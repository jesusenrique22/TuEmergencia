import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../features/telemedicine/data/webrtc_call_controller.dart';
import 'app_realtime.dart';

/// Sesión de llamada activa (pantalla completa o minimizada).
class ActiveCallService extends ChangeNotifier {
  ActiveCallService._();
  static final ActiveCallService instance = ActiveCallService._();

  static const _logName = 'ActiveCallService';

  WebRtcCallController? _controller;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<void>? _videoLayoutSub;
  String _conversationId = '';
  String _peerName = '';
  bool _isVideo = true;
  bool _isOutgoing = true;
  String _status = 'En llamada';
  bool _muted = false;
  bool _cameraOff = false;
  bool _minimized = false;

  bool get hasActiveCall => _conversationId.isNotEmpty;
  bool get isMinimized => _minimized && hasActiveCall && _controller != null;
  String get conversationId => _conversationId;
  String get peerName => _peerName;
  bool get isVideo => _isVideo;
  String get status => _status;
  bool get muted => _muted;
  bool get cameraOff => _cameraOff;
  WebRtcCallController? get controller => _controller;

  bool isParked(String conversationId) =>
      hasActiveCall && _minimized && _conversationId == conversationId;

  bool blocksNewCall(String targetConversationId, {bool restoring = false}) {
    if (!hasActiveCall) return false;
    if (restoring && _conversationId == targetConversationId) return false;
    return true;
  }

  void markInCall({
    required String conversationId,
    required String peerName,
    required bool isVideo,
    required bool isOutgoing,
    String status = 'En llamada',
  }) {
    _conversationId = conversationId;
    _peerName = peerName;
    _isVideo = isVideo;
    _isOutgoing = isOutgoing;
    _status = status;
    _minimized = false;
    developer.log('sesión activa conv=$conversationId', name: _logName);
    notifyListeners();
  }

  void park({
    required WebRtcCallController controller,
    required StreamSubscription<String>? statusSub,
    required StreamSubscription<void>? videoLayoutSub,
    required String conversationId,
    required String peerName,
    required bool isVideo,
    required bool isOutgoing,
    required String status,
    required bool muted,
    required bool cameraOff,
  }) {
    _controller = controller;
    _conversationId = conversationId;
    _peerName = peerName;
    _isVideo = isVideo;
    _isOutgoing = isOutgoing;
    _status = status;
    _muted = muted;
    _cameraOff = cameraOff;
    _minimized = true;

    unawaited(statusSub?.cancel());
    unawaited(videoLayoutSub?.cancel());
    _statusSub = controller.statusStream.listen(_onStatus);
    _videoLayoutSub = null;
    developer.log('llamada minimizada conv=$conversationId', name: _logName);
    notifyListeners();
  }

  void _onStatus(String s) {
    if (s == 'ended' || s == 'rejected') {
      unawaited(hangUp(notifyPeer: false));
    } else if (s == 'connected') {
      _status = 'En llamada';
      notifyListeners();
    }
  }

  ({
    WebRtcCallController controller,
    String status,
    bool muted,
    bool cameraOff,
  })?
  resume(String conversationId) {
    if (!hasActiveCall ||
        _conversationId != conversationId ||
        _controller == null) {
      return null;
    }

    _minimized = false;
    notifyListeners();

    unawaited(_statusSub?.cancel());
    _statusSub = null;
    _videoLayoutSub = null;

    final snapshot = (
      controller: _controller!,
      status: _status,
      muted: _muted,
      cameraOff: _cameraOff,
    );

    _controller = null;
    notifyListeners();
    return snapshot;
  }

  void updateUiState({String? status, bool? muted, bool? cameraOff}) {
    if (status != null) _status = status;
    if (muted != null) _muted = muted;
    if (cameraOff != null) _cameraOff = cameraOff;
    if (hasActiveCall && !_minimized) notifyListeners();
  }

  void expandToFullScreen() {
    if (!hasActiveCall) return;
    AppRealtime.navigateToVideoCall(
      conversationId: _conversationId,
      peerName: _peerName,
      callType: _isVideo ? 'video' : 'audio',
      isOutgoing: _isOutgoing,
      acceptAlreadySent: true,
      restoreSession: true,
    );
  }

  /// Aviso breve y vuelve a la llamada activa (p. ej. intentó llamar a otro contacto).
  void notifyBusyAndReturnToCall() {
    final ctx = AppRealtime.navigatorKey?.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).clearSnackBars();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.phone_in_talk, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ya estás en llamada con $_peerName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      expandToFullScreen();
    });
    developer.log('aviso llamada activa → volver a $_peerName', name: _logName);
  }

  /// La pantalla de llamada terminó; no toca el controller si sigue minimizado.
  void releaseSession(String conversationId) {
    if (_conversationId != conversationId) return;
    if (_controller != null && _minimized) return;

    _conversationId = '';
    _peerName = '';
    _minimized = false;
    _controller = null;
    unawaited(_statusSub?.cancel());
    _statusSub = null;
    notifyListeners();
  }

  Future<void> hangUp({bool notifyPeer = true}) async {
    if (!hasActiveCall && _controller == null) return;

    _minimized = false;
    await _statusSub?.cancel();
    _statusSub = null;
    await _videoLayoutSub?.cancel();
    _videoLayoutSub = null;

    final call = _controller;
    final convId = _conversationId;
    _controller = null;
    _conversationId = '';

    try {
      if (call != null) {
        if (notifyPeer) call.hangUp();
        await call.dispose();
      } else if (notifyPeer && convId.isNotEmpty) {
        AppRealtime.chatSocket.endCall(convId);
      }
      if (convId.isNotEmpty) {
        AppRealtime.chatSocket.leaveCallRoom(convId);
        AppRealtime.chatSocket.leaveConversation(convId);
      }
      unawaited(AppRealtime.connectIfNeeded());
    } catch (e, st) {
      developer.log('hangUp', name: _logName, error: e, stackTrace: st);
    }

    notifyListeners();
  }

  Future<void> clear() => hangUp(notifyPeer: true);
}
