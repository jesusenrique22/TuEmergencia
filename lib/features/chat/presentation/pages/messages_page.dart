import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/debug/dev_tools_config.dart';
import '../../../../core/connectivity/service_connectivity.dart';
import '../../../../core/network/gateway_health.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/active_call_service.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../auth/domain/models/role.dart';
import '../../data/chat_api_service.dart';
import '../../utils/chat_media_url.dart';

/// Mensajería paciente–médico: pestaña Chats (bidireccional) e Historial clínico.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _chat = ChatApiService();
  final _imagePicker = ImagePicker();

  List<ChatConversationItem> _conversations = [];
  ChatConversationItem? _activeChat;
  List<ChatMessageItem> _chatMessages = [];
  List<ClinicalFeedItem> _clinicalItems = [];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loadingChats = true;
  bool _loadingThread = false;
  bool _loadingClinical = true;
  bool _sending = false;
  String? _chatError;
  String? _clinicalError;
  String? _joinedConversationId;
  Timer? _chatRetryTimer;
  int _chatLoadAttempts = 0;

  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _conversationSub;
  StreamSubscription<bool>? _connectionSub;
  bool _socketConnected = false;

  bool get _isDoctor => AppSession.activeRole == Role.doctor;
  bool _openedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
    _messageSub = AppRealtime.chatSocket.onMessage.listen(_onSocketMessage);
    _conversationSub =
        AppRealtime.chatSocket.onConversationUpdated.listen(_onConversationUpdated);
    _socketConnected = AppRealtime.chatSocket.isConnected;
    _connectionSub = AppRealtime.chatSocket.onConnectionChanged.listen((ok) {
      if (!mounted) return;
      setState(() => _socketConnected = ok);
      if (ok) {
        ServiceConnectivity.instance.invalidateCache();
        if (_joinedConversationId != null) {
          AppRealtime.chatSocket.joinConversation(_joinedConversationId!);
        }
        if (_loadingChats || _conversations.isEmpty) {
          unawaited(_loadChats());
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(AppRealtime.connectIfNeeded());
    });
    // Mantener socket activo en Mensajes (recibir call:incoming aunque no estés en el chat).
    AppRealtime.maintainSessionConnection();
    _loadChats();
    _loadClinical();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openedFromArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map || args['conversationId'] == null) return;
    _openedFromArgs = true;
    final id = args['conversationId'] as String;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _tabController.index = 0;
      if (_conversations.isEmpty) await _loadChats();
      for (final c in _conversations) {
        if (c.id == id) {
          await _openChat(c);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _chatRetryTimer?.cancel();
    if (_joinedConversationId != null) {
      AppRealtime.chatSocket.leaveConversation(_joinedConversationId!);
    }
    _messageSub?.cancel();
    _conversationSub?.cancel();
    _connectionSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    final kind = data['kind']?.toString() ?? 'chat';
    if (kind == 'clinical') {
      _loadClinical();
      return;
    }

    final convId = data['conversationId']?.toString();
    final raw = data['message'];
    if (convId == null || raw is! Map) return;

    final msg = ChatMessageItem.fromJson(Map<String, dynamic>.from(raw));
    if (_activeChat?.id != convId) {
      _loadChats();
      return;
    }
    if (_chatMessages.any((m) => m.id == msg.id)) return;
    setState(() => _chatMessages = [..._chatMessages, msg]);
    _scrollToBottom();
  }

  void _onConversationUpdated(Map<String, dynamic> data) {
    final kind = data['kind']?.toString() ?? 'chat';
    if (kind == 'clinical') {
      _loadClinical();
      return;
    }
    final convId = data['conversationId']?.toString();
    if (convId != null && _activeChat?.id == convId) {
      unawaited(_reloadActiveThread());
    }
    _loadChats();
  }

  Future<void> _reloadActiveThread() async {
    final conv = _activeChat;
    if (conv == null) return;
    try {
      final msgs = await _chat.getMessages(conv.id, kind: ChatMessageKind.chat);
      if (!mounted || _activeChat?.id != conv.id) return;
      setState(() => _chatMessages = msgs);
      _scrollToBottom();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadChats({bool isRetry = false}) async {
    if (!isRetry) _chatLoadAttempts = 0;
    _chatRetryTimer?.cancel();
    setState(() {
      _loadingChats = true;
      _chatError = null;
    });
    try {
      final list = await _chat.listConversations();
      list.sort((a, b) {
        final at = a.lastChatMessageAt ??
            a.lastClinicalMessageAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastChatMessageAt ??
            b.lastClinicalMessageAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      if (!mounted) return;
      _chatLoadAttempts = 0;
      setState(() {
        _conversations = list;
        _loadingChats = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _chatError = e.message;
        _loadingChats = false;
      });
      _scheduleChatRetry();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chatError = 'No se pudieron cargar los chats';
        _loadingChats = false;
      });
      _scheduleChatRetry();
    }
  }

  void _scheduleChatRetry() {
    if (!mounted || _chatLoadAttempts >= 4) return;
    _chatLoadAttempts++;
    _chatRetryTimer?.cancel();
    _chatRetryTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) unawaited(_loadChats(isRetry: true));
    });
  }

  Future<void> _loadClinical() async {
    setState(() {
      _loadingClinical = true;
      _clinicalError = null;
    });
    try {
      final items = _isDoctor
          ? (await _chat.getClinicalFeed())
              .map(
                (m) => ClinicalFeedItem(
                  id: m.id,
                  title: 'Indicación clínica',
                  body: m.text,
                  doctorName: m.patientName ?? m.senderName,
                  date: m.createdAt,
                ),
              )
              .toList()
          : await _chat.getPatientClinicalTimeline();
      if (!mounted) return;
      setState(() {
        _clinicalItems = items;
        _loadingClinical = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _clinicalError = e.message;
        _loadingClinical = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clinicalError = 'No se pudo cargar el historial clínico';
        _loadingClinical = false;
      });
    }
  }

  Future<void> _openChat(ChatConversationItem c) async {
    if (_joinedConversationId != null && _joinedConversationId != c.id) {
      AppRealtime.chatSocket.leaveConversation(_joinedConversationId!);
    }
    _joinedConversationId = c.id;

    setState(() {
      _activeChat = c;
      _loadingThread = true;
      _chatMessages = [];
    });

    final connectFuture =
        AppRealtime.ensureConnected(timeout: const Duration(seconds: 3));
    final msgsFuture = _chat.getMessages(c.id, kind: ChatMessageKind.chat);

    final socketOk = await connectFuture;
    if (!mounted || _joinedConversationId != c.id) return;
    if (socketOk) {
      AppRealtime.chatSocket.joinConversation(c.id);
    }

    try {
      final msgs = await msgsFuture;
      if (!mounted) return;
      setState(() {
        _chatMessages = msgs;
        _loadingThread = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendChat() async {
    final conv = _activeChat;
    final text = _textController.text.trim();
    if (conv == null || text.isEmpty) return;

    setState(() => _sending = true);
    try {
      ChatMessageItem? sent;
      final socketOk = await AppRealtime.ensureConnected(
        timeout: const Duration(seconds: 3),
      );
      if (socketOk) {
        sent = await AppRealtime.chatSocket.sendMessage(
          conversationId: conv.id,
          text: text,
          kind: 'chat',
        );
      }
      final message = sent ??
          await _chat.sendMessage(
            conversationId: conv.id,
            text: text,
            kind: ChatMessageKind.chat,
          );

      _textController.clear();
      if (!_chatMessages.any((m) => m.id == message.id)) {
        setState(() => _chatMessages = [..._chatMessages, message]);
      }
      await _loadChats();
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final conv = _activeChat;
    if (conv == null || _sending) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 2048,
    );
    if (file == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final bytes = await file.readAsBytes();
      final caption = _textController.text.trim();
      final message = await _chat.sendMessage(
        conversationId: conv.id,
        text: caption,
        imageBytes: bytes,
        imageMimeType: _mimeFromFileName(file.name),
      );
      _textController.clear();
      if (!_chatMessages.any((m) => m.id == message.id)) {
        setState(() => _chatMessages = [..._chatMessages, message]);
      }
      await _loadChats();
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _mimeFromFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void _openImagePreview(String imageUrl) {
    final url = chatMediaFullUrl(imageUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(url),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNewChatSheet() async {
    try {
      final contacts = await _chat.listContactsForNewChat();
      if (!mounted) return;
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _conversations.isEmpty
                  ? 'Necesitas una cita con un ${_isDoctor ? 'paciente' : 'médico'} para iniciar un chat.'
                  : 'Ya tienes chat con todos tus contactos que tienen cita. Abre uno de la lista.',
            ),
          ),
        );
        return;
      }

      final picked = await showModalBottomSheet<ChatContactItem>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDoctor ? 'Nueva conversación' : 'Nueva conversación',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isDoctor
                          ? 'Pacientes con cita contigo que aún no tienen chat'
                          : 'Médicos con los que tienes cita y aún no tienes chat',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (_, i) {
                    final c = contacts[i];
                    return ListTile(
                      leading: SafeAvatar(radius: 24, imageUrl: c.profilePic),
                      title: Text(c.name),
                      subtitle: Text(
                        _isDoctor ? 'Iniciar chat' : 'Iniciar chat',
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (picked == null || !mounted) return;
      final conv = await _chat.getOrCreateConversation(
        doctorId: _isDoctor ? null : picked.id,
        patientId: _isDoctor ? picked.id : null,
      );
      await _loadChats();
      await _openChat(conv);
      if (mounted) setState(() => _tabController.index = 0);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar el chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startCall({required bool video}) async {
    final conv = _activeChat;
    if (conv == null) return;

    final active = ActiveCallService.instance;
    if (active.hasActiveCall) {
      if (active.conversationId == conv.id) {
        active.expandToFullScreen();
      } else {
        active.notifyBusyAndReturnToCall();
      }
      return;
    }

    final gatewayUp = await isGatewayReachable();
    if (!mounted) return;
    if (!gatewayUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El gateway WebSocket no está activo. En una terminal ejecuta:\n'
            'cd realtime-gateway && pnpm run dev',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    final connected = await AppRealtime.ensureConnected(
      timeout: const Duration(seconds: 6),
    );
    if (!mounted) return;
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo conectar al gateway (${ApiConfig.socketUrl}). '
            'Cierra sesión, vuelve a entrar y comprueba JWT_SECRET igual en backend y realtime-gateway.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (_joinedConversationId != null) {
      AppRealtime.chatSocket.joinConversation(_joinedConversationId!);
      AppRealtime.chatSocket.joinCallRoom(_joinedConversationId!);
    }

    if (!mounted) return;
    AppRealtime.navigateToVideoCall(
      conversationId: conv.id,
      peerName: _peerName(conv),
      callType: video ? 'video' : 'audio',
      isOutgoing: true,
    );
  }

  String _peerName(ChatConversationItem c) =>
      _isDoctor ? c.patientName : c.doctorName;

  String? _peerAvatar(ChatConversationItem c) =>
      _isDoctor ? c.patientAvatar : c.doctorAvatar;

  String _formatListTime(DateTime? dt) => AppDateFormat.listTime(dt);

  String _formatMessageTime(DateTime dt) => AppDateFormat.timeHm(dt);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final inChatThread = _activeChat != null && _tabController.index == 0;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: inChatThread && !wide
            ? Text(_peerName(_activeChat!))
            : const Text('Mensajes'),
        leading: inChatThread && !wide
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _activeChat = null),
              )
            : null,
        actions: [
          if (DevToolsConfig.enabled)
            IconButton(
              tooltip: 'Debug gateway',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.gatewayDebug),
            ),
          if (inChatThread) ...[
            Tooltip(
              message: _socketConnected
                  ? 'Tiempo real activo'
                  : 'Sin conexión al gateway (${ApiConfig.socketUrl})',
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _socketConnected ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: _socketConnected ? Colors.greenAccent : Colors.orange,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Llamada de voz',
              icon: const Icon(Icons.phone_rounded),
              onPressed: () => _startCall(video: false),
            ),
            IconButton(
              tooltip: 'Videollamada',
              icon: const Icon(Icons.videocam_rounded),
              onPressed: () => _startCall(video: true),
            ),
          ],
        ],
        bottom: inChatThread && !wide
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Chats', icon: Icon(Icons.chat_rounded, size: 20)),
                  Tab(
                    text: 'Historial clínico',
                    icon: Icon(Icons.medical_information_outlined, size: 20),
                  ),
                ],
              ),
      ),
      floatingActionButton: _tabController.index == 0 && _activeChat == null
          ? FloatingActionButton.extended(
              onPressed: _showNewChatSheet,
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Nuevo'),
            )
          : null,
      child: inChatThread && !wide
          ? _buildChatThread()
          : TabBarView(
              controller: _tabController,
              children: [
                wide ? _buildChatsWide() : _buildChatsNarrow(),
                _buildClinicalTab(),
              ],
            ),
    );
  }

  Widget _buildChatsWide() {
    return Row(
      children: [
        SizedBox(width: 320, child: _buildChatList()),
        const VerticalDivider(width: 1),
        Expanded(
          child: _activeChat == null ? _selectChatHint() : _buildChatThread(),
        ),
      ],
    );
  }

  Widget _buildChatsNarrow() {
    if (_activeChat != null) return _buildChatThread();
    return _buildChatList();
  }

  Widget _selectChatHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'Selecciona un chat o inicia uno nuevo',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_loadingChats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_chatError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_chatError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => unawaited(_loadChats()),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined,
                  size: 56, color: AppColors.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                _isDoctor
                    ? 'Aún no tienes conversaciones.\nPulsa «Nuevo» para escribir a un paciente con cita.'
                    : 'Aún no tienes conversaciones.\nPulsa «Nuevo» para escribir a un médico con cita.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final c = _conversations[i];
        final selected = _activeChat?.id == c.id;
        final preview = c.lastChatMessage ??
            c.lastClinicalMessage ??
            'Toca para abrir el chat';
        final time = _formatListTime(
          c.lastChatMessageAt ?? c.lastClinicalMessageAt,
        );

        return ListTile(
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SafeAvatar(radius: 26, imageUrl: _peerAvatar(c)),
          title: Text(
            _peerName(c),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: time.isNotEmpty
              ? Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          onTap: () => _openChat(c),
        );
      },
    );
  }

  Widget _buildChatThread() {
    return Column(
      children: [
        if (MediaQuery.of(context).size.width >= 800 && _activeChat != null)
          Material(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
            child: ListTile(
              leading: SafeAvatar(radius: 20, imageUrl: _peerAvatar(_activeChat!)),
              title: Text(
                _peerName(_activeChat!),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Chat en tiempo real'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone_rounded),
                    onPressed: () => _startCall(video: false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_rounded),
                    onPressed: () => _startCall(video: true),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _loadingThread
              ? const Center(child: CircularProgressIndicator())
              : _chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'Di hola a ${_activeChat != null ? _peerName(_activeChat!) : 'tu contacto'}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      itemCount: _chatMessages.length,
                      itemBuilder: (_, i) => _buildBubble(_chatMessages[i], i),
                    ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildBubble(ChatMessageItem m, int index) {
    final mine = m.senderId == AppSession.currentUser?.id;
    final showDate = index == 0 ||
        !_sameDay(_chatMessages[index - 1].createdAt, m.createdAt);

    return Column(
      children: [
        if (showDate) _buildDateChip(m.createdAt),
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (m.hasImage) ...[
                  GestureDetector(
                    onTap: () => _openImagePreview(m.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        chatMediaFullUrl(m.imageUrl),
                        width: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 220,
                            height: 160,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          width: 220,
                          height: 120,
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  if (m.text.isNotEmpty &&
                      m.text != '📷 Foto') ...[
                    const SizedBox(height: 6),
                    Text(
                      m.text,
                      style: TextStyle(
                        color: mine ? Colors.white : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ] else
                  Text(
                    m.text,
                    style: TextStyle(
                      color: mine ? Colors.white : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _formatMessageTime(m.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppDateFormat.dayMonthYear(dt),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _sending ? null : _pickAndSendImage,
            tooltip: 'Enviar foto',
            icon: const Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mensaje o pie de foto',
                filled: true,
                fillColor: AppColors.primaryLight.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _sending ? null : _sendChat,
              icon: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalTab() {
    if (_loadingClinical) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_clinicalError != null) {
      return Center(child: Text(_clinicalError!));
    }
    if (_clinicalItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_information_outlined,
                  size: 56, color: AppColors.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                _isDoctor
                    ? 'Las indicaciones que envíes desde Historial Médico aparecerán aquí.'
                    : 'Aquí verás indicaciones de tu médico y entradas de tu historial clínico.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _clinicalItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = _clinicalItems[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        item.isHistoryEntry
                            ? Icons.history_edu_rounded
                            : Icons.medical_services_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.doctorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _formatListTime(item.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.isHistoryEntry)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Historial',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
