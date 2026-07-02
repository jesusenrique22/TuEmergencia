import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/debug/call_debug_log.dart';
import '../../chat/data/chat_socket_service.dart';

class WebRtcCallController {
  WebRtcCallController({required this.socket, required this.conversationId});

  static const _logName = 'WebRtcCallController';

  final ChatSocketService socket;
  final String conversationId;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _disposed = false;
  bool _videoEnabled = false;
  bool _remoteDescriptionSet = false;
  bool _remoteAnswerApplied = false;
  bool _handlingOffer = false;
  bool _mediaReady = false;
  bool _offerSent = false;
  bool _acceptHandled = false;
  bool _pendingAccept = false;
  bool _outgoingMediaReady = false;
  bool _localCameraMissing = false;
  bool _cameraPermissionGranted = false;
  bool _videoInputAvailable = false;
  bool _negotiateVideo = false;
  bool _videoTransceiverEnsured = false;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  final Set<String> _seenIceCandidateKeys = {};
  final Set<String> _seenSignalIds = {};

  Map<String, dynamic>? _queuedOffer;

  final _statusController = StreamController<String>.broadcast();
  final _videoLayoutController = StreamController<void>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  /// Dispara cuando hay frames nuevos o cambia el stream (refrescar [RTCVideoView]).
  Stream<void> get onVideoLayoutChanged => _videoLayoutController.stream;

  bool get hasLocalVideoTrack =>
      (_localStream?.getVideoTracks().length ?? 0) > 0;

  bool get localCameraMissing => _localCameraMissing;

  bool get cameraPermissionGranted => _cameraPermissionGranted;

  /// Texto para banner cuando no hay preview local (permiso vs simulador vs fallo hardware).
  String get localVideoIssueHint {
    if (hasLocalVideoTrack && localVideoActive) return '';
    if (!_cameraPermissionGranted) {
      return 'Permite la cámara en Ajustes → TuEmergencia → Cámara.';
    }
    if (!_videoInputAvailable || isIosSimulator) {
      return 'Permiso OK. Simulador: menú I/O (o Features) → Camera → elige la cámara del Mac. '
          'Cuelga y vuelve a llamar.';
    }
    return 'Permiso OK, pero la cámara no respondió. Cierra TuEmergencia por completo '
        '(apps recientes) y vuelve a llamar.';
  }

  bool get hasRemoteVideoTrack =>
      (_remoteStream?.getVideoTracks().length ?? 0) > 0;

  bool get localVideoActive {
    final tracks = _localStream?.getVideoTracks() ?? [];
    return tracks.any((t) => t.enabled);
  }

  bool get remoteVideoActive {
    final tracks = _remoteStream?.getVideoTracks() ?? [];
    return tracks.any((t) => t.enabled);
  }

  static bool get isIos {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool get isIosSimulator {
    if (!isIos) return false;
    try {
      final env = Platform.environment;
      const keys = [
        'SIMULATOR_DEVICE_NAME',
        'SIMULATOR_UDID',
        'SIMULATOR_MODEL_IDENTIFIER',
        'SIMULATOR_RUNTIME_VERSION',
      ];
      if (keys.any(env.containsKey)) return true;
      final model = env['SIMULATOR_MODEL_IDENTIFIER'] ?? '';
      return model.toLowerCase().contains('simulator');
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> get _peerConfig => {
        'iceServers': ApiConfig.webRtcIceServers,
        'sdpSemantics': 'unified-plan',
      };

  Map<String, dynamic> _sessionConstraints(bool video) => {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': video,
      };

  void _notifyVideoLayout() {
    if (!_videoLayoutController.isClosed) {
      _videoLayoutController.add(null);
    }
  }

  void _wireRendererCallbacks() {
    void onLayout() => _notifyVideoLayout();
    localRenderer.onResize = onLayout;
    remoteRenderer.onResize = onLayout;
    localRenderer.onFirstFrameRendered = onLayout;
    remoteRenderer.onFirstFrameRendered = onLayout;
  }

  /// Restricciones de video para [getUserMedia] (ordenadas de más a menos estrictas).
  List<dynamic> _videoGetUserMediaAttempts() {
    if (kIsWeb) {
      return [
        {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 24, 'max': 30},
        },
      ];
    }
    if (isIos) {
      return [
        true,
        {
          'width': {'ideal': 640, 'max': 1280},
          'height': {'ideal': 480, 'max': 720},
          'frameRate': {'ideal': 24, 'max': 30},
        },
        {'facingMode': 'user'},
        {
          'mandatory': {'minWidth': '640', 'minHeight': '480'},
          'optional': <dynamic>[],
        },
      ];
    }
    return [
      {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 24, 'max': 30},
      },
      true,
    ];
  }

  Future<void> _ensureVideoTransceivers({required bool wantsVideo}) async {
    if (_peer == null || !wantsVideo || _videoTransceiverEnsured) return;

    final hasLocalVideo = (_localStream?.getVideoTracks().length ?? 0) > 0;
    if (hasLocalVideo) {
      _videoTransceiverEnsured = true;
      return;
    }

    await _peer!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    _videoTransceiverEnsured = true;
    developer.log('transceiver video RecvOnly (sin cámara local)', name: _logName);
    CallDebugLog.media(
      'Transceiver video RecvOnly',
      detail: 'negociar video remoto sin cámara local',
    );
  }

  Future<void> _preferVideoCodecsForMobile() async {
    if (kIsWeb || _peer == null) return;
    try {
      final caps = await getRtpSenderCapabilities('video');
      final all = caps.codecs ?? [];
      if (all.isEmpty) return;

      final vp8 = all.where((c) => c.mimeType.toLowerCase().contains('vp8')).toList();
      final h264 = all.where((c) => c.mimeType.toLowerCase().contains('h264')).toList();
      final rest = all.where((c) {
        final m = c.mimeType.toLowerCase();
        return !m.contains('vp8') && !m.contains('h264');
      }).toList();
      final ordered = [...vp8, ...h264, ...rest];

      final transceivers = await _peer!.getTransceivers();
      for (final t in transceivers) {
        if (t.sender.track?.kind == 'video') {
          await t.setCodecPreferences(ordered);
        }
      }
      developer.log(
        'codecs video mobile VP8=${vp8.length} H264=${h264.length}',
        name: _logName,
      );
    } catch (e, st) {
      developer.log('_preferVideoCodecsForMobile', name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> _syncRemoteTracksFromReceivers() async {
    if (_peer == null || _disposed) return;
    try {
      final receivers = await _peer!.getReceivers();
      final inbound = receivers
          .map((r) => r.track)
          .whereType<MediaStreamTrack>()
          .where((t) => t.kind == 'video' || t.kind == 'audio')
          .toList();
      if (inbound.isEmpty) return;

      var stream = _remoteStream;
      stream ??= await createLocalMediaStream('remote-$conversationId');

      for (final track in inbound) {
        track.enabled = true;
        final already = stream.getTracks().any((t) => t.id == track.id);
        if (!already) stream.addTrack(track);
      }

      await _bindRemoteStream(stream);
    } catch (e, st) {
      developer.log('_syncRemoteTracksFromReceivers', name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> init() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _wireRendererCallbacks();
    } on MissingPluginException {
      throw Exception(
        'WebRTC no está disponible en esta build. En iOS ejecuta: '
        'cd ios && pod install, luego flutter clean && flutter run.',
      );
    } on PlatformException catch (e) {
      throw Exception('No se pudo iniciar WebRTC: ${e.message ?? e.code}');
    }
  }

  Future<bool> ensurePermissions({required bool video}) async {
    if (kIsWeb) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    if (video) {
      final cam = await Permission.camera.request();
      _cameraPermissionGranted = cam.isGranted;
      if (!cam.isGranted) return false;
    } else {
      _cameraPermissionGranted = false;
    }
    return true;
  }

  Future<bool> _probeVideoInputAvailable() async {
    if (kIsWeb) return true;
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      return devices.any((d) => d.kind == 'videoinput');
    } catch (e, st) {
      developer.log('enumerateDevices', name: _logName, error: e, stackTrace: st);
      return true;
    }
  }

  bool _dedupeSignal(Map<String, dynamic> data) {
    final id = data['signalId']?.toString();
    if (id == null || id.isEmpty) return false;
    if (_seenSignalIds.contains(id)) return true;
    _seenSignalIds.add(id);
    return false;
  }

  String? _currentUserId() => AppSession.currentUser?.id;

  bool _isFromSelf(Map<String, dynamic> data) {
    final from = data['fromUserId']?.toString();
    final me = _currentUserId();
    return from != null && me != null && from == me;
  }

  Future<void> _onRemoteTrack(RTCTrackEvent event) async {
    if (event.streams.isNotEmpty) {
      await _bindRemoteStream(event.streams.first);
      return;
    }
    final track = event.track;
    for (final existing in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
      if (existing.id == track.id) return;
    }
    _remoteStream ??= await createLocalMediaStream('remote-$conversationId');
    _remoteStream!.addTrack(track);
    await _bindRemoteStream(_remoteStream!);
  }

  Future<void> _bindRemoteStream(MediaStream stream) async {
    if (_disposed) return;
    _remoteStream = stream;
    for (final track in stream.getTracks()) {
      track.enabled = true;
    }

    final videoTracks = stream.getVideoTracks();
    try {
      if (videoTracks.isNotEmpty) {
        await remoteRenderer.setSrcObject(
          stream: stream,
          trackId: videoTracks.first.id,
        );
      } else {
        await remoteRenderer.setSrcObject(stream: stream);
      }
    } catch (e, st) {
      developer.log('setSrcObject remote', name: _logName, error: e, stackTrace: st);
      remoteRenderer.srcObject = stream;
    }

    developer.log(
      'remote stream audio=${stream.getAudioTracks().length} '
      'video=${stream.getVideoTracks().length}',
      name: _logName,
    );
    CallDebugLog.media(
      'Stream remoto',
      level: RealtimeDebugLevel.success,
      detail: 'audio=${stream.getAudioTracks().length} video=${stream.getVideoTracks().length}',
    );
    _notifyVideoLayout();
  }

  Future<void> _createPeer() async {
    _peer = await createPeerConnection(_peerConfig);
    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      socket.sendIceCandidate(
        conversationId: conversationId,
        candidate: candidate.toMap(),
      );
    };
    _peer!.onTrack = (event) {
      unawaited(_onRemoteTrack(event));
    };
    _peer!.onConnectionState = (state) {
      final name = state.toString();
      developer.log('connectionState=$name', name: _logName);
      CallDebugLog.media('connectionState=$name');
      if (name.contains('Connected')) {
        CallDebugLog.media(
          'Peer conectado',
          level: RealtimeDebugLevel.success,
        );
        unawaited(_syncRemoteTracksFromReceivers());
        if (!_statusController.isClosed) {
          _statusController.add('connected');
        }
      } else if (name.contains('Failed') || name.contains('Closed')) {
        CallDebugLog.media(
          'Peer desconectado',
          level: RealtimeDebugLevel.warn,
          detail: name,
        );
        if (!_statusController.isClosed) {
          _statusController.add('ended');
        }
      }
    };
    _peer!.onIceConnectionState = (state) {
      developer.log('iceConnectionState=$state', name: _logName);
      CallDebugLog.media('iceConnectionState=$state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        CallDebugLog.media(
          'ICE conectado',
          level: RealtimeDebugLevel.success,
        );
        unawaited(_syncRemoteTracksFromReceivers());
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        CallDebugLog.media(
          'ICE falló — ¿TURN configurado?',
          level: RealtimeDebugLevel.error,
        );
      }
    };
  }

  Future<MediaStream> _openLocalMediaStream({required bool video}) async {
    const audioConstraints = {
      'echoCancellation': true,
      'noiseSuppression': true,
    };
    if (!video) {
      return navigator.mediaDevices.getUserMedia({
        'audio': audioConstraints,
        'video': false,
      });
    }

    Object? lastError;
    for (final videoConstraints in _videoGetUserMediaAttempts()) {
      MediaStream? stream;
      try {
        stream = await navigator.mediaDevices.getUserMedia({
          'audio': audioConstraints,
          'video': videoConstraints,
        });
        if (stream.getVideoTracks().isEmpty) {
          lastError = 'getUserMedia sin track de video';
          developer.log(
            'getUserMedia devolvió solo audio — reintento',
            name: _logName,
          );
          await stream.dispose();
          continue;
        }
        return stream;
      } catch (e, st) {
        lastError = e;
        await stream?.dispose();
        developer.log(
          'getUserMedia intento fallido',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }

    // Sin cámara local: no abortar la videollamada — audio + video remoto (RecvOnly).
    developer.log(
      'Sin track de video tras todos los intentos — continuando solo con audio',
      name: _logName,
    );
    CallDebugLog.media(
      'Cámara no disponible — fallback audio',
      level: RealtimeDebugLevel.warn,
      detail: lastError?.toString(),
    );
    return navigator.mediaDevices.getUserMedia({
      'audio': audioConstraints,
      'video': false,
    });
  }

  /// Si getUserMedia devolvió solo audio, intenta abrir video en un stream aparte (iOS/simulador).
  Future<void> _tryAttachIosVideoTrack() async {
    if (!isIos || _localStream == null) return;
    if (_localStream!.getVideoTracks().isNotEmpty) return;

    const attempts = <dynamic>[
      {
        'width': {'ideal': 640, 'max': 1280},
        'height': {'ideal': 480, 'max': 720},
      },
      true,
      {
        'mandatory': {'minWidth': '640', 'minHeight': '480'},
        'optional': <dynamic>[],
      },
    ];

    for (final videoConstraints in attempts) {
      try {
        final videoStream = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': videoConstraints,
        });
        final tracks = videoStream.getVideoTracks();
        if (tracks.isEmpty) {
          await videoStream.dispose();
          continue;
        }
        for (final track in tracks) {
          track.enabled = true;
          _localStream!.addTrack(track);
        }
        developer.log(
          'video track añadido en stream separado (${tracks.length})',
          name: _logName,
        );
        return;
      } catch (e, st) {
        developer.log('_tryAttachIosVideoTrack', name: _logName, error: e, stackTrace: st);
      }
    }
  }

  Future<void> _attachLocalMedia({required bool video}) async {
    _videoEnabled = video;
    _negotiateVideo = video;
    _localCameraMissing = false;
    final ok = await ensurePermissions(video: video);
    if (!ok) throw Exception('Permisos de cámara o micrófono denegados');

    if (video) {
      _videoInputAvailable = await _probeVideoInputAvailable();
    }

    _localStream = await _openLocalMediaStream(video: video);

    if (video && isIos) {
      await _tryAttachIosVideoTrack();
    }

    for (final track in _localStream!.getTracks()) {
      track.enabled = true;
    }

    final videoTracks = _localStream!.getVideoTracks();
    developer.log(
      'local stream audio=${_localStream!.getAudioTracks().length} '
      'video=${videoTracks.length} ios=$isIos simulator=$isIosSimulator',
      name: _logName,
    );
    debugPrint(
      '[WebRTC] local tracks audio=${_localStream!.getAudioTracks().length} '
      'video=${videoTracks.length} (ios=$isIos sim=$isIosSimulator)',
    );
    CallDebugLog.media(
      'Media local',
      detail: 'audio=${_localStream!.getAudioTracks().length} '
          'video=${videoTracks.length} ios=$isIos sim=$isIosSimulator '
          'permCam=$_cameraPermissionGranted videoIn=$_videoInputAvailable',
    );

    if (video && videoTracks.isEmpty) {
      _localCameraMissing = true;
      _videoEnabled = false;
      final detail = _cameraPermissionGranted
          ? (_videoInputAvailable
              ? 'permiso OK, getUserMedia sin video'
              : 'permiso OK, sin videoinput (simulador?)')
          : 'permiso cámara denegado';
      CallDebugLog.media(
        'Sin cámara local — audio + video remoto',
        level: RealtimeDebugLevel.warn,
        detail: detail,
      );
      debugPrint('[WebRTC] Sin cámara local ($detail) — continúa con audio + video remoto.');
    }

    try {
      await localRenderer.setSrcObject(stream: _localStream);
    } catch (e, st) {
      developer.log('setSrcObject local', name: _logName, error: e, stackTrace: st);
      localRenderer.srcObject = _localStream;
    }
    _notifyVideoLayout();

    if (_peer == null || _localStream == null) return;

    for (final track in _localStream!.getTracks()) {
      await _peer!.addTrack(track, _localStream!);
    }
    await _ensureVideoTransceivers(wantsVideo: _negotiateVideo);
    await _preferVideoCodecsForMobile();
  }

  String _iceKey(Map<String, dynamic> raw) {
    final c = raw['candidate'] as String? ?? '';
    final mid = raw['sdpMid'] as String? ?? '';
    final idx = raw['sdpMLineIndex']?.toString() ?? '';
    return '$c|$mid|$idx';
  }

  Future<void> _safeAddCandidate(RTCIceCandidate candidate) async {
    if (_peer == null) return;
    if (!_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }
    try {
      await _peer!.addCandidate(candidate);
    } catch (_) {
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _queueOrAddCandidate(Map<String, dynamic> raw) async {
    final line = raw['candidate'] as String?;
    if (line == null || line.isEmpty) return;

    final key = _iceKey(raw);
    if (_seenIceCandidateKeys.contains(key)) return;
    _seenIceCandidateKeys.add(key);

    await _safeAddCandidate(
      RTCIceCandidate(
        line,
        raw['sdpMid'] as String?,
        raw['sdpMLineIndex'] as int?,
      ),
    );
  }

  Future<void> _drainPendingCandidates() async {
    if (_peer == null || !_remoteDescriptionSet) return;
    if (kIsWeb) {
      await Future<void>.delayed(Duration.zero);
    }
    final pending = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final c in pending) {
      await _safeAddCandidate(c);
    }
  }

  Future<void> _setRemoteDescription(RTCSessionDescription desc) async {
    await _peer!.setRemoteDescription(desc);
    _remoteDescriptionSet = true;
    await _drainPendingCandidates();
    await _syncRemoteTracksFromReceivers();
  }

  Future<void> _applyRemoteAnswer(Map<String, dynamic> sdpMap) async {
    if (_peer == null || _disposed || _remoteAnswerApplied) return;

    _remoteAnswerApplied = true;
    try {
      await _setRemoteDescription(
        RTCSessionDescription(sdpMap['sdp'] as String, sdpMap['type'] as String),
      );
      developer.log('answer aplicada (caller)', name: _logName);
      CallDebugLog.media('Answer remota aplicada', level: RealtimeDebugLevel.success);
    } catch (e, st) {
      _remoteAnswerApplied = false;
      developer.log('applyRemoteAnswer', name: _logName, error: e, stackTrace: st);
      CallDebugLog.media('Error aplicando answer', level: RealtimeDebugLevel.error, detail: e);
    }
  }

  void _registerSharedHandlers() {
    socket.onCallIce((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;
      final c = data['candidate'];
      if (c is Map) {
        await _queueOrAddCandidate(Map<String, dynamic>.from(c));
      }
    }, conversationId: conversationId);
    socket.onCallEnded((_) {
      if (!_statusController.isClosed) _statusController.add('ended');
    }, conversationId: conversationId);
    socket.onCallRejected((_) {
      if (!_statusController.isClosed) _statusController.add('rejected');
    }, conversationId: conversationId);
  }

  void _registerOfferHandler({required bool wantsVideo}) {
    socket.onCallOffer((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;

      if (!_mediaReady) {
        _queuedOffer = data;
        developer.log('offer en cola (media no lista)', name: _logName);
        return;
      }
      await _handleRemoteOffer(data, fallbackVideo: wantsVideo);
    }, conversationId: conversationId);
  }

  Future<void> _flushQueuedOffer({required bool wantsVideo}) async {
    final offer = _queuedOffer;
    if (offer == null) return;
    _queuedOffer = null;
    await _handleRemoteOffer(offer, fallbackVideo: wantsVideo);
  }

  Future<void> _onOutgoingPeerAccepted(bool wantsVideo) async {
    if (_acceptHandled || _disposed) return;
    _acceptHandled = true;
    developer.log('call:accepted → createOffer', name: _logName);
    socket.joinCallRoom(conversationId);
    await _createAndSendOffer(wantsVideo);
  }

  /// Registra listeners y prepara media. Llamar [sendOutgoingInvite] después.
  Future<void> startOutgoingCall({required bool video, required String callType}) async {
    CallDebugLog.resetIceCounters();
    CallDebugLog.media('Iniciando llamada saliente', detail: 'conv=$conversationId tipo=$callType');
    final wantsVideo = callType != 'audio' && video;

    socket.offCallEvents();
    _registerSharedHandlers();

    socket.onCallAccepted((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (!_outgoingMediaReady) {
        _pendingAccept = true;
        developer.log('call:accepted en cola (media aún no lista)', name: _logName);
        return;
      }
      await _onOutgoingPeerAccepted(wantsVideo);
    }, conversationId: conversationId);

    socket.onCallAnswer((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;
      final sdp = data['sdp'];
      if (sdp is! Map) return;
      await _applyRemoteAnswer(Map<String, dynamic>.from(sdp));
    }, conversationId: conversationId);

    await _createPeer();
    await _attachLocalMedia(video: wantsVideo);
    _mediaReady = true;
    _outgoingMediaReady = true;

    if (_pendingAccept) {
      _pendingAccept = false;
      await _onOutgoingPeerAccepted(wantsVideo);
    }
  }

  /// Debe llamarse solo después de [startOutgoingCall] (peer listo + listeners activos).
  Future<bool> sendOutgoingInvite({
    required String callerName,
    required String callType,
  }) async {
    developer.log('call:invite conv=$conversationId', name: _logName);
    return socket.inviteCall(
      conversationId: conversationId,
      callType: callType,
      callerName: callerName,
    );
  }

  Future<void> _createAndSendOffer(bool video) async {
    if (_peer == null || _disposed || _offerSent) return;
    _offerSent = true;
    await _ensureVideoTransceivers(wantsVideo: video);
    final offer = await _peer!.createOffer(_sessionConstraints(video));
    await _peer!.setLocalDescription(offer);
    socket.sendOffer(
      conversationId: conversationId,
      sdp: offer.toMap(),
      callType: video ? 'video' : 'audio',
    );
    developer.log(
      'offer enviada (video=$video localVideo=${_localStream?.getVideoTracks().length ?? 0})',
      name: _logName,
    );
    CallDebugLog.media(
      'Offer enviada',
      detail: 'video=$video tracks=${_localStream?.getVideoTracks().length ?? 0}',
    );
  }

  Future<void> acceptIncomingCall({
    required bool video,
    required String callType,
    bool skipAcceptSignal = false,
  }) async {
    CallDebugLog.resetIceCounters();
    CallDebugLog.media('Aceptando llamada entrante', detail: 'conv=$conversationId tipo=$callType');
    final wantsVideo = callType != 'audio' && video;

    socket.offCallEvents();
    _registerSharedHandlers();
    _registerOfferHandler(wantsVideo: wantsVideo);

    await _createPeer();
    await _attachLocalMedia(video: wantsVideo);

    socket.joinCallRoom(conversationId);
    _mediaReady = true;

    await _flushQueuedOffer(wantsVideo: wantsVideo);

    if (!skipAcceptSignal) {
      developer.log('call:accept (peer listo)', name: _logName);
      socket.acceptCall(conversationId);
    }

    await _flushQueuedOffer(wantsVideo: wantsVideo);
  }

  Future<void> _handleRemoteOffer(
    Map<String, dynamic> data, {
    required bool fallbackVideo,
  }) async {
    if (_handlingOffer || _peer == null) return;
    _handlingOffer = true;

    try {
      final offerCallType = data['callType'] as String? ?? (fallbackVideo ? 'video' : 'audio');
      final offerVideo = offerCallType != 'audio';
      final sdp = data['sdp'];
      if (sdp is! Map) return;

      developer.log('offer recibida (video=$offerVideo)', name: _logName);

      await _setRemoteDescription(
        RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
      );

      await _ensureVideoTransceivers(wantsVideo: offerVideo);
      final answer = await _peer!.createAnswer(_sessionConstraints(offerVideo));
      await _peer!.setLocalDescription(answer);
      socket.sendAnswer(conversationId: conversationId, sdp: answer.toMap());
      developer.log('answer enviada', name: _logName);
      CallDebugLog.media(
        'Answer enviada',
        level: RealtimeDebugLevel.success,
        detail: 'conv=$conversationId',
      );
      await _syncRemoteTracksFromReceivers();
    } catch (e, st) {
      developer.log('handleRemoteOffer', name: _logName, error: e, stackTrace: st);
      debugPrint('[WebRTC] Error negociando offer/answer: $e');
      CallDebugLog.media('Error negociando offer/answer', level: RealtimeDebugLevel.error, detail: e);
      if (!_statusController.isClosed) _statusController.add('ended');
    } finally {
      _handlingOffer = false;
    }
  }

  Future<void> toggleMute(bool muted) async {
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> toggleCamera(bool off) async {
    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !off;
    }
  }

  bool get hasVideo => _videoEnabled;

  void hangUp() {
    if (_disposed) return;
    try {
      socket.endCall(conversationId);
    } catch (e, st) {
      developer.log('hangUp', name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    CallDebugLog.media('Sesión WebRTC cerrada', detail: 'conv=$conversationId');
    try {
      socket.offCallEvents();
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.stop();
      }
      for (final track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
      await _remoteStream?.dispose();
      _remoteStream = null;
      await _peer?.close();
      _peer = null;
      _pendingRemoteCandidates.clear();
      _seenIceCandidateKeys.clear();
      _seenSignalIds.clear();
      _queuedOffer = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();
      if (!_statusController.isClosed) {
        await _statusController.close();
      }
      if (!_videoLayoutController.isClosed) {
        await _videoLayoutController.close();
      }
    } catch (e, st) {
      developer.log('dispose', name: _logName, error: e, stackTrace: st);
      rethrow;
    }
  }
}
