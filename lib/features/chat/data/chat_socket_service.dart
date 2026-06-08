import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/auth/app_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/debug/call_debug_log.dart';
import '../../../core/debug/realtime_debug_log.dart';
import '../../../core/network/gateway_health.dart';
import 'chat_api_service.dart';

typedef MessageHandler = void Function(Map<String, dynamic> payload);
typedef ConversationUpdateHandler = void Function(Map<String, dynamic> payload);
typedef IncomingCallHandler = void Function(IncomingCallEvent event);

class IncomingCallEvent {
  final String conversationId;
  final String callType;
  final String callerId;
  final String callerName;

  const IncomingCallEvent({
    required this.conversationId,
    required this.callType,
    required this.callerId,
    required this.callerName,
  });
}

/// Cliente Socket.IO para chat en tiempo real y señalización WebRTC.
class ChatSocketService {
  io.Socket? _socket;
  bool _connecting = false;
  bool _authRejected = false;
  String? lastConnectionError;
  DateTime? _lastGatewayUnreachableLog;
  final _debug = RealtimeDebugLog.instance;

  bool get authRejected => _authRejected;
  bool get isConnecting => _connecting;
  Timer? _connectDebounce;
  Timer? _connectWatchdog;
  int _connectGeneration = 0;

  static const _maxBufferedSignals = 24;
  final Map<String, List<Map<String, dynamic>>> _signalingBuffer = {};
  void Function(Map<String, dynamic>)? _callAcceptedHandler;
  void Function(Map<String, dynamic>)? _callOfferHandler;
  void Function(Map<String, dynamic>)? _callAnswerHandler;
  void Function(Map<String, dynamic>)? _callIceHandler;
  void Function(Map<String, dynamic>)? _callEndedHandler;
  void Function(Map<String, dynamic>)? _callRejectedHandler;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallController = StreamController<IncomingCallEvent>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _clinicRosterController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated =>
      _conversationController.stream;
  Stream<IncomingCallEvent> get onIncomingCall => _incomingCallController.stream;
  Stream<Map<String, dynamic>> get onNotificationNew =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onClinicRosterUpdated =>
      _clinicRosterController.stream;
  Stream<Map<String, dynamic>> get onEmergencyUpdated =>
      _emergencyUpdatedController.stream;
  Stream<Map<String, dynamic>> get onEmergencyLocation =>
      _emergencyLocationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Espera a que el socket esté listo (p. ej. antes de una llamada).
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!AppSession.isLoggedIn || AppSession.token == null) return false;
    if (isConnected) return true;

    if (!ApiConfig.openedViaDevTunnel) {
      final gatewayUp = await isGatewayReachable(
        timeout: const Duration(seconds: 3),
      );
      if (!gatewayUp) {
        debugPrint(
          '[ChatSocket] Gateway no responde en ${ApiConfig.gatewayHealthUrl}',
        );
        return false;
      }
    }

    connect();
    if (isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription<bool> sub;
    sub = onConnectionChanged.listen((ok) {
      if (ok && !completer.isCompleted) {
        completer.complete(true);
        unawaited(sub.cancel());
      }
    });

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(isConnected);
        unawaited(sub.cancel());
      }
    });

    return completer.future;
  }

  /// En web: polling (XHR). En iOS/Android la librería `socket_io_client` solo
  /// implementa WebSocket en dart:io (`io_transports.dart`). Si se pide solo
  /// `polling`, el cliente abre `ws://` con `transport=polling` y el handshake
  /// hace timeout (HTTP /health sigue funcionando).
  List<String> get _socketTransports {
    if (kIsWeb) return const ['polling'];
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        return const ['websocket'];
      }
    } catch (_) {
      // Plataformas sin dart:io
    }
    return const ['polling', 'websocket'];
  }

  void resetStalledConnection() {
    if (isConnected) return;
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
    if (_connecting || _socket != null) {
      debugPrint('[ChatSocket] Conexión colgada — reiniciando socket');
      _connecting = false;
      _tearDownSocket();
    }
  }

  void connect() {
    if (!AppSession.isLoggedIn || AppSession.token == null) return;
    if (_authRejected) return;
    if (_socket?.connected == true) return;

    _connectDebounce?.cancel();
    _connectDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_connectNow());
    });
  }

  Future<void> _connectNow() async {
    if (!AppSession.isLoggedIn || AppSession.token == null) return;
    if (_authRejected) return;
    if (_socket?.connected == true) return;
    if (_connecting) return;

    final url = ApiConfig.socketUrl;
    if (!ApiConfig.openedViaDevTunnel) {
      final gatewayUp = await isGatewayReachable(
        timeout: const Duration(seconds: 3),
      );
      if (!gatewayUp) {
        lastConnectionError = 'Gateway no responde en ${ApiConfig.gatewayHealthUrl}';
        _debug.log(
          'ChatSocket',
          lastConnectionError!,
          level: RealtimeDebugLevel.error,
        );
        final now = DateTime.now();
        if (_lastGatewayUnreachableLog == null ||
            now.difference(_lastGatewayUnreachableLog!) >
                const Duration(seconds: 15)) {
          _lastGatewayUnreachableLog = now;
          debugPrint(
            '[ChatSocket] Sin gateway en ${ApiConfig.gatewayHealthUrl} — '
            'cd realtime-gateway && pnpm run dev',
          );
        }
        return;
      }
    }

    _tearDownSocket();
    _connecting = true;
    final generation = ++_connectGeneration;
    final token = AppSession.token!;

    debugPrint('[ChatSocket] Conectando a $url …');
    lastConnectionError = null;
    _debug.log('ChatSocket', 'Conectando…', detail: url);

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(_socketTransports)
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setTimeout(10000)
          .setAuth({'token': token})
          .build(),
    );

    _connectWatchdog?.cancel();
    _connectWatchdog = Timer(const Duration(seconds: 12), () {
      if (generation != _connectGeneration) return;
      if (_connecting && !(_socket?.connected ?? false)) {
        debugPrint('[ChatSocket] Timeout de conexión — reintentando');
        _connecting = false;
        _tearDownSocket();
        connect();
      }
    });

    _socket!
      ..onConnect((_) {
        if (generation != _connectGeneration) return;
        _connectWatchdog?.cancel();
        _connectWatchdog = null;
        _connecting = false;
        lastConnectionError = null;
        developer.log('socket conectado', name: 'ChatSocket');
        debugPrint('[ChatSocket] Conectado a $url');
        _debug.log('ChatSocket', 'Conectado', level: RealtimeDebugLevel.success, detail: url);
        _connectionController.add(true);
      })
      ..onDisconnect((_) {
        if (generation != _connectGeneration) return;
        _connecting = false;
        developer.log('socket desconectado', name: 'ChatSocket');
        _debug.log('ChatSocket', 'Desconectado', level: RealtimeDebugLevel.warn);
        _connectionController.add(false);
      })
      ..onConnectError((err) {
        if (generation != _connectGeneration) return;
        _connectWatchdog?.cancel();
        _connectWatchdog = null;
        _connecting = false;
        lastConnectionError = err.toString();
        developer.log('connect_error', name: 'ChatSocket', error: err);
        debugPrint('[ChatSocket] Error de conexión ($url): $err');
        _debug.log(
          'ChatSocket',
          'Error de conexión',
          level: RealtimeDebugLevel.error,
          detail: '$url — $err',
        );
        _connectionController.add(false);
        if (_isAuthError(err)) {
          _authRejected = true;
          _debug.log(
            'ChatSocket',
            'Token rechazado — cierra sesión y vuelve a entrar',
            level: RealtimeDebugLevel.error,
          );
          debugPrint(
            '[ChatSocket] Token rechazado; deteniendo reconexiones hasta nuevo login.',
          );
        }
        _tearDownSocket(disableReconnection: _authRejected);
      })
      ..on('message:new', (data) {
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('conversation:updated', (data) {
        if (data is Map) {
          _conversationController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('call:incoming', (data) {
        if (data is! Map) return;
        final map = Map<String, dynamic>.from(data);
        final event = IncomingCallEvent(
          conversationId: map['conversationId']?.toString() ?? '',
          callType: map['callType']?.toString() ?? 'video',
          callerId: map['callerId']?.toString() ?? '',
          callerName: map['callerName']?.toString() ?? 'Usuario',
        );
        developer.log('call:incoming ${event.conversationId}', name: 'ChatSocket');
        CallDebugLog.signal(
          'call:incoming de ${event.callerName}',
          level: RealtimeDebugLevel.success,
          detail: 'conv=${event.conversationId} tipo=${event.callType}',
        );
        _incomingCallController.add(event);
      })
      ..on('notification:new', (data) {
        if (data is Map) {
          _notificationController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('clinic:roster:updated', (data) {
        if (data is Map) {
          _clinicRosterController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('emergency:updated', (data) {
        if (data is Map) {
          _emergencyUpdatedController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('emergency:location', (data) {
        if (data is Map) {
          _emergencyLocationController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('emergency:assigned', (data) {
        if (data is Map) {
          _emergencyUpdatedController.add(Map<String, dynamic>.from(data));
        }
      });

    _attachCallSignalingListeners();

    _socket!.connect();
  }

  void _attachCallSignalingListeners() {
    final s = _socket;
    if (s == null) return;

    s
      ..off('call:accepted')
      ..off('call:offer')
      ..off('call:answer')
      ..off('call:ice')
      ..off('call:ended')
      ..off('call:rejected')
      ..on('call:accepted', (data) {
        _dispatchCallSignal(
          'call:accepted',
          data,
          _callAcceptedHandler,
          level: RealtimeDebugLevel.success,
        );
      })
      ..on('call:offer', (data) {
        _dispatchCallSignal('call:offer', data, _callOfferHandler);
      })
      ..on('call:answer', (data) {
        _dispatchCallSignal(
          'call:answer',
          data,
          _callAnswerHandler,
          level: RealtimeDebugLevel.success,
        );
      })
      ..on('call:ice', (data) {
        if (data is! Map) return;
        final map = Map<String, dynamic>.from(data);
        final c = map['candidate'];
        if (c is Map) {
          CallDebugLog.iceReceived(sdpMid: c['sdpMid']?.toString());
        }
        if (_callIceHandler != null) {
          _callIceHandler!(map);
        } else {
          _bufferCallSignal('call:ice', map);
        }
      })
      ..on('call:ended', (data) {
        _dispatchCallSignal(
          'call:ended',
          data,
          _callEndedHandler,
          level: RealtimeDebugLevel.warn,
        );
      })
      ..on('call:rejected', (data) {
        _dispatchCallSignal(
          'call:rejected',
          data,
          _callRejectedHandler,
          level: RealtimeDebugLevel.warn,
        );
      });
  }

  void _dispatchCallSignal(
    String kind,
    dynamic data,
    void Function(Map<String, dynamic>)? handler, {
    RealtimeDebugLevel level = RealtimeDebugLevel.info,
  }) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final conv = map['conversationId']?.toString() ?? '?';
    if (kind == 'call:offer') {
      CallDebugLog.signal(
        'call:offer ←',
        detail: 'conv=$conv tipo=${map['callType'] ?? "?"}',
      );
    } else if (kind == 'call:answer') {
      CallDebugLog.signal(
        'call:answer ←',
        level: RealtimeDebugLevel.success,
        detail: 'conv=$conv',
      );
    } else if (kind == 'call:accepted') {
      CallDebugLog.signal(
        'call:accepted ←',
        level: RealtimeDebugLevel.success,
        detail: 'conv=$conv',
      );
    } else if (kind == 'call:ended') {
      CallDebugLog.signal(
        'call:ended ←',
        level: RealtimeDebugLevel.warn,
        detail: 'conv=$conv',
      );
    } else if (kind == 'call:rejected') {
      CallDebugLog.signal(
        'call:rejected ←',
        level: RealtimeDebugLevel.warn,
        detail: 'conv=$conv',
      );
    }
    if (handler != null) {
      handler(map);
    } else {
      _bufferCallSignal(kind, map);
    }
  }

  void _bufferCallSignal(String kind, Map<String, dynamic> map) {
    final convId = map['conversationId']?.toString();
    if (convId == null || convId.isEmpty) return;
    final key = '$kind:$convId';
    final list = _signalingBuffer.putIfAbsent(key, () => []);
    if (list.length >= _maxBufferedSignals) list.removeAt(0);
    list.add(map);
    CallDebugLog.signal(
      '$kind (en cola)',
      level: RealtimeDebugLevel.warn,
      detail: 'conv=$convId — handler aún no registrado',
    );
  }

  void _flushSignalingBuffer(
    String kind,
    String conversationId,
    void Function(Map<String, dynamic>) handler,
  ) {
    final key = '$kind:$conversationId';
    final pending = _signalingBuffer.remove(key);
    if (pending == null || pending.isEmpty) return;
    CallDebugLog.signal(
      '$kind (reproduciendo ${pending.length})',
      level: RealtimeDebugLevel.success,
      detail: 'conv=$conversationId',
    );
    for (final map in pending) {
      handler(map);
    }
  }

  void _clearCallHandlers() {
    _callAcceptedHandler = null;
    _callOfferHandler = null;
    _callAnswerHandler = null;
    _callIceHandler = null;
    _callEndedHandler = null;
    _callRejectedHandler = null;
    _signalingBuffer.clear();
  }

  bool _isAuthError(dynamic err) {
    if (err is Map) {
      final message = err['message']?.toString() ?? '';
      if (message.contains('Token inválido') ||
          message.toLowerCase().contains('invalid token') ||
          message.toLowerCase().contains('jwt')) {
        return true;
      }
    }
    final text = err?.toString() ?? '';
    return text.contains('Token inválido') ||
        text.toLowerCase().contains('invalid token');
  }

  void _tearDownSocket({bool disableReconnection = false}) {
    _connectDebounce?.cancel();
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        if (disableReconnection) {
          s.io.options?['reconnection'] = false;
        }
        s.disconnect();
        s.dispose();
      } catch (_) {
        // ignore
      }
    }
  }

  void disconnect() {
    _connectDebounce?.cancel();
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
    _connecting = false;
    _connectGeneration++;
    _clearCallHandlers();
    _tearDownSocket();
    _connectionController.add(false);
  }

  /// Limpia el bloqueo por JWT inválido (p. ej. tras login o hot restart con sesión nueva).
  void resetAuthState() {
    _authRejected = false;
    lastConnectionError = null;
    _debug.log('ChatSocket', 'Estado auth reseteado');
  }

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', conversationId);
  }

  void joinEmergency(String emergencyRequestId) {
    _socket?.emit('emergency:join', emergencyRequestId);
  }

  void leaveEmergency(String emergencyRequestId) {
    _socket?.emit('emergency:leave', emergencyRequestId);
  }

  Future<ChatMessageItem?> sendMessage({
    required String conversationId,
    required String text,
    String kind = 'chat',
  }) async {
    final completer = Completer<ChatMessageItem?>();
    _socket?.emitWithAck(
      'message:send',
      {'conversationId': conversationId, 'text': text, 'kind': kind},
      ack: (data) {
        if (data is Map && data['ok'] == true && data['message'] is Map) {
          completer.complete(
            ChatMessageItem.fromJson(
              Map<String, dynamic>.from(data['message'] as Map),
            ),
          );
        } else {
          completer.complete(null);
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  Future<bool> inviteCall({
    required String conversationId,
    required String callType,
    required String callerName,
  }) async {
    CallDebugLog.signal(
      'call:invite →',
      detail: 'conv=$conversationId tipo=$callType',
    );
    if (_socket == null || !isConnected) return false;

    final completer = Completer<bool>();
    _socket!.emitWithAck(
      'call:invite',
      {
        'conversationId': conversationId,
        'callType': callType,
        'callerName': callerName,
      },
      ack: (data) {
        if (data is Map && data['ok'] == true) {
          CallDebugLog.signal(
            'call:invite ✓',
            level: RealtimeDebugLevel.success,
            detail: 'callee=${data['calleeId'] ?? "?"}',
          );
          completer.complete(true);
          return;
        }
        final err = data is Map ? data['error']?.toString() : null;
        CallDebugLog.signal(
          'call:invite ✗',
          level: RealtimeDebugLevel.error,
          detail: err ?? 'sin respuesta del gateway',
        );
        completer.complete(false);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        CallDebugLog.signal(
          'call:invite timeout',
          level: RealtimeDebugLevel.error,
          detail: 'conv=$conversationId',
        );
        return false;
      },
    );
  }

  void acceptCall(String conversationId) {
    CallDebugLog.signal('call:accept →', detail: 'conv=$conversationId');
    _socket?.emit('call:accept', {'conversationId': conversationId});
  }

  /// Entra a la sala de señalización WebRTC (debe coincidir con el backend).
  void joinCallRoom(String conversationId) {
    CallDebugLog.signal('call:join →', detail: 'conv=$conversationId');
    _socket?.emit('call:join', {'conversationId': conversationId});
  }

  void leaveCallRoom(String conversationId) {
    CallDebugLog.signal('call:leave →', detail: 'conv=$conversationId');
    _socket?.emit('call:leave', {'conversationId': conversationId});
  }

  void rejectCall(String conversationId) {
    CallDebugLog.signal(
      'call:reject →',
      level: RealtimeDebugLevel.warn,
      detail: 'conv=$conversationId',
    );
    _socket?.emit('call:reject', {'conversationId': conversationId});
  }

  void sendOffer({
    required String conversationId,
    required Map<String, dynamic> sdp,
    required String callType,
  }) {
    CallDebugLog.signal(
      'call:offer →',
      detail: 'conv=$conversationId tipo=$callType',
    );
    _socket?.emit('call:offer', {
      'conversationId': conversationId,
      'sdp': sdp,
      'callType': callType,
    });
  }

  void sendAnswer({
    required String conversationId,
    required Map<String, dynamic> sdp,
  }) {
    CallDebugLog.signal('call:answer →', detail: 'conv=$conversationId');
    _socket?.emit('call:answer', {
      'conversationId': conversationId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String conversationId,
    required Map<String, dynamic> candidate,
  }) {
    CallDebugLog.iceSent(sdpMid: candidate['sdpMid']?.toString());
    _socket?.emit('call:ice', {
      'conversationId': conversationId,
      'candidate': candidate,
    });
  }

  void endCall(String conversationId) {
    CallDebugLog.signal(
      'call:end →',
      level: RealtimeDebugLevel.warn,
      detail: 'conv=$conversationId',
    );
    _socket?.emit('call:end', {'conversationId': conversationId});
  }

  void onCallAccepted(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callAcceptedHandler = handler;
    _flushSignalingBuffer('call:accepted', conversationId, handler);
  }

  void onCallOffer(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callOfferHandler = handler;
    _flushSignalingBuffer('call:offer', conversationId, handler);
  }

  void onCallAnswer(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callAnswerHandler = handler;
    _flushSignalingBuffer('call:answer', conversationId, handler);
  }

  void onCallIce(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callIceHandler = handler;
    _flushSignalingBuffer('call:ice', conversationId, handler);
  }

  void onCallEnded(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callEndedHandler = handler;
    _flushSignalingBuffer('call:ended', conversationId, handler);
  }

  void onCallRejected(
    void Function(Map<String, dynamic>) handler, {
    required String conversationId,
  }) {
    _callRejectedHandler = handler;
    _flushSignalingBuffer('call:rejected', conversationId, handler);
  }

  void offCallEvents() {
    _clearCallHandlers();
  }
}
