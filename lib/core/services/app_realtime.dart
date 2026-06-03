import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/app_session.dart';
import '../config/api_config.dart';
import '../debug/realtime_debug_log.dart';
import '../debug/call_debug_log.dart';
import '../navigation/app_routes.dart';
import '../network/gateway_health.dart';
import '../../features/chat/data/chat_socket_service.dart';
import '../../features/chat/presentation/widgets/incoming_call_dialog.dart';
import 'active_call_service.dart';
import '../../features/telemedicine/presentation/widgets/active_call_banner.dart';

/// Conexión Socket.IO global y manejo de llamadas entrantes.
///
/// Con sesión iniciada el socket permanece conectado al gateway hasta logout
/// o cierre de la app (el SO corta la conexión). No se desconecta al cambiar de pantalla.
class AppRealtime {
  AppRealtime._();

  static const _logName = 'AppRealtime';

  static final ChatSocketService chatSocket = ChatSocketService();
  static final _doctorProfileRefreshController =
      StreamController<void>.broadcast();
  static Stream<void> get onDoctorProfileRefresh =>
      _doctorProfileRefreshController.stream;
  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _incomingListenerAttached = false;
  static bool _connectionGuardAttached = false;
  static bool _lifecycleAttached = false;
  static bool _userInitiatedDisconnect = false;
  static String? _showingIncomingForConversationId;
  static IncomingCallEvent? _pendingIncoming;

  static void bindNavigator(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    _attachIncomingCallListener();
    _attachConnectionGuard();
    _attachLifecycle();
    ActiveCallOverlay.attach(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maintainSessionConnection();
    });
    _tryShowPendingIncomingCall();
  }

  /// Conecta si hay sesión; desconecta solo tras logout explícito.
  static void maintainSessionConnection() {
    if (!AppSession.isLoggedIn) {
      disconnect();
      return;
    }
    unawaited(connectIfNeeded());
  }

  static Future<void> connectIfNeeded() async {
    if (!AppSession.isLoggedIn) return;
    _userInitiatedDisconnect = false;
    _attachIncomingCallListener();
    _attachConnectionGuard();

    if (chatSocket.isConnected || chatSocket.isConnecting) return;

    ApiConfig.logResolvedEndpoints();
    final reachable = await isGatewayReachable();
    if (!reachable) {
      final msg =
          'Gateway no responde en ${ApiConfig.socketUrl}/health — cd realtime-gateway && pnpm run dev';
      RealtimeDebugLog.instance.log('AppRealtime', msg, level: RealtimeDebugLevel.error);
      if (kDebugMode) debugPrint('[AppRealtime] $msg');
      return;
    }

    RealtimeDebugLog.instance.log('AppRealtime', 'Gateway OK, iniciando socket…');
    chatSocket.connect();
  }

  /// Tras login nuevo: socket limpio con el JWT actual.
  static void reconnectAfterAuth() {
    chatSocket.resetAuthState();
    disconnect();
    unawaited(connectIfNeeded());
  }

  /// Conecta al gateway Socket.IO (puerto 3001) y espera hasta [timeout].
  static Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!AppSession.isLoggedIn) return false;
    await connectIfNeeded();
    return chatSocket.ensureConnected(timeout: timeout);
  }

  /// Tras aceptar/rechazar invitación a clínica u otros cambios de sedes.
  static void notifyDoctorProfileRefresh() {
    _doctorProfileRefreshController.add(null);
  }

  /// Solo al cerrar sesión (logout). No usar al navegar entre pantallas.
  static void disconnect() {
    _userInitiatedDisconnect = true;
    chatSocket.disconnect();
    _showingIncomingForConversationId = null;
    _pendingIncoming = null;
    unawaited(ActiveCallService.instance.clear());
  }

  static void _attachLifecycle() {
    if (_lifecycleAttached) return;
    _lifecycleAttached = true;
    final binding = WidgetsBinding.instance;
    binding.addObserver(_AppLifecycleReconnectObserver());
  }

  static void _attachConnectionGuard() {
    if (_connectionGuardAttached) return;
    _connectionGuardAttached = true;
    chatSocket.onConnectionChanged.listen((connected) {
      if (connected) return;
      if (_userInitiatedDisconnect || !AppSession.isLoggedIn) return;
      if (chatSocket.authRejected) return;
      developer.log('socket cayó — reintentando conexión', name: _logName);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!_userInitiatedDisconnect &&
            AppSession.isLoggedIn &&
            !chatSocket.isConnected &&
            !chatSocket.authRejected) {
          unawaited(connectIfNeeded());
        }
      });
    });
  }

  static void _attachIncomingCallListener() {
    if (_incomingListenerAttached) return;
    _incomingListenerAttached = true;
    chatSocket.onIncomingCall.listen(_handleIncomingCall);
    developer.log('listener call:incoming activo', name: _logName);
  }

  static void _handleIncomingCall(IncomingCallEvent event) {
    if (event.conversationId.isEmpty) return;
    if (!_shouldHandleIncomingCalls()) {
      _pendingIncoming = null;
      return;
    }

    final nav = navigatorKey?.currentState;
    final currentRoute = nav != null
        ? ModalRoute.of(nav.context)?.settings.name
        : null;
    if (currentRoute == AppRoutes.videoCall) {
      developer.log(
        'ignorando incoming: ya en pantalla de llamada',
        name: _logName,
      );
      return;
    }

    final active = ActiveCallService.instance;
    if (active.hasActiveCall) {
      if (active.conversationId == event.conversationId) {
        developer.log('incoming misma conv — volver a llamada', name: _logName);
        active.expandToFullScreen();
        return;
      }
      developer.log(
        'ignorando incoming: llamada activa con ${active.peerName}',
        name: _logName,
      );
      chatSocket.rejectCall(event.conversationId);
      return;
    }

    developer.log(
      'call:incoming conv=${event.conversationId} de=${event.callerName} (${event.callerId})',
      name: _logName,
    );
    debugPrint(
      '[AppRealtime] Llamada entrante de ${event.callerName} '
      '(conv=${event.conversationId})',
    );
    CallDebugLog.signal(
      'Llamada entrante — ${event.callerName}',
      level: RealtimeDebugLevel.success,
      detail: 'conv=${event.conversationId} tipo=${event.callType}',
    );

    _pendingIncoming = event;
    _tryShowPendingIncomingCall();
  }

  static void navigateToVideoCall({
    required String conversationId,
    required String peerName,
    required String callType,
    required bool isOutgoing,
    bool acceptAlreadySent = false,
    bool restoreSession = false,
  }) {
    final active = ActiveCallService.instance;

    if (!restoreSession && active.blocksNewCall(conversationId)) {
      if (active.conversationId == conversationId) {
        active.expandToFullScreen();
      } else {
        active.notifyBusyAndReturnToCall();
      }
      developer.log(
        'bloqueada nueva llamada — activa con ${active.peerName}',
        name: _logName,
      );
      return;
    }

    final nav = navigatorKey?.currentState;
    if (nav == null) {
      debugPrint('[AppRealtime] Sin navigator — no se abre videollamada');
      return;
    }
    final args = {
      'conversationId': conversationId,
      'peerName': peerName,
      'callType': callType,
      'isOutgoing': isOutgoing,
      'acceptAlreadySent': acceptAlreadySent,
      'restoreSession': restoreSession,
    };
    // Tras cerrar un dialog, push en el mismo frame a veces se pierde (iOS).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final root = navigatorKey?.currentState;
      if (root == null) return;
      root.pushNamed(AppRoutes.videoCall, arguments: args);
    });
  }

  static void _tryShowPendingIncomingCall() {
    final event = _pendingIncoming;
    if (event == null) return;
    if (!_shouldHandleIncomingCalls()) {
      _pendingIncoming = null;
      _showingIncomingForConversationId = null;
      return;
    }

    final nav = navigatorKey?.currentState;
    if (nav == null) {
      developer.log('sin navigator, llamada en cola', name: _logName);
      return;
    }

    final ctx = nav.overlay?.context ?? navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) {
      developer.log('sin contexto overlay, llamada en cola', name: _logName);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryShowPendingIncomingCall();
      });
      return;
    }

    if (_showingIncomingForConversationId == event.conversationId) return;
    _showingIncomingForConversationId = event.conversationId;
    _pendingIncoming = null;

    unawaited(_showIncomingDialog(nav, ctx, event));
  }

  static bool _shouldHandleIncomingCalls() {
    if (!AppSession.isLoggedIn) return false;
    return true;
  }

  static Future<void> _showIncomingDialog(
    NavigatorState nav,
    BuildContext ctx,
    IncomingCallEvent event,
  ) async {
    await IncomingCallDialog.show(
      ctx,
      event: event,
      onReject: () {
        chatSocket.rejectCall(event.conversationId);
        Navigator.of(ctx, rootNavigator: true).pop();
        _showingIncomingForConversationId = null;
      },
      onAccept: () {
        chatSocket.joinCallRoom(event.conversationId);
        chatSocket.acceptCall(event.conversationId);
        _showingIncomingForConversationId = null;
        Navigator.of(ctx, rootNavigator: true).pop();
        navigateToVideoCall(
          conversationId: event.conversationId,
          peerName: event.callerName,
          callType: event.callType,
          isOutgoing: false,
          acceptAlreadySent: true,
        );
      },
    );

    if (_showingIncomingForConversationId == event.conversationId) {
      _showingIncomingForConversationId = null;
    }
  }
}

/// Reconecta al volver a primer plano (p. ej. tras minimizar la app).
final class _AppLifecycleReconnectObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppRealtime.maintainSessionConnection();
    }
  }
}
