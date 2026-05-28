import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../auth/domain/models/role.dart';
import '../../data/chat_api_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _chat = ChatApiService();
  List<ChatConversationItem> _conversations = [];
  ChatConversationItem? _active;
  List<ChatMessageItem> _messages = [];
  final _textController = TextEditingController();
  bool _loadingList = true;
  bool _loadingThread = false;
  bool _sending = false;
  String? _error;

  bool get _isDoctor => AppSession.activeRole == Role.doctor;

  bool _openedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
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
      if (_conversations.isEmpty) await _loadConversations();
      for (final c in _conversations) {
        if (c.id == id) {
          await _openConversation(c);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final list = await _chat.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loadingList = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingList = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las conversaciones';
        _loadingList = false;
      });
    }
  }

  Future<void> _openConversation(ChatConversationItem c) async {
    setState(() {
      _active = c;
      _loadingThread = true;
      _messages = [];
    });
    try {
      final msgs = await _chat.getMessages(c.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loadingThread = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
    }
  }

  Future<void> _send() async {
    final conv = _active;
    final text = _textController.text.trim();
    if (conv == null || text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chat.sendMessage(conversationId: conv.id, text: text);
      _textController.clear();
      await _openConversation(conv);
      await _loadConversations();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _peerName(ChatConversationItem c) =>
      _isDoctor ? c.patientName : c.doctorName;

  String? _peerAvatar(ChatConversationItem c) =>
      _isDoctor ? c.patientAvatar : c.doctorAvatar;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(_active != null ? _peerName(_active!) : 'Mensajes'),
        leading: _active != null && !wide
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _active = null),
              )
            : null,
      ),
      child: wide ? _buildWide() : _buildNarrow(),
    );
  }

  Widget _buildWide() {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildConversationList()),
        const VerticalDivider(width: 1),
        Expanded(child: _active == null ? _selectHint() : _buildThread()),
      ],
    );
  }

  Widget _buildNarrow() {
    if (_active != null) return _buildThread();
    return _buildConversationList();
  }

  Widget _selectHint() {
    return const Center(
      child: Text(
        'Selecciona una conversación',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildConversationList() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay mensajes aún.\nTu médico puede escribirte desde el historial clínico.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (_, i) {
        final c = _conversations[i];
        final selected = _active?.id == c.id;
        return ListTile(
          selected: selected,
          leading: SafeAvatar(radius: 22, imageUrl: _peerAvatar(c)),
          title: Text(
            _peerName(c),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            c.lastMessage ?? 'Sin mensajes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _openConversation(c),
        );
      },
    );
  }

  Widget _buildThread() {
    return Column(
      children: [
        Expanded(
          child: _loadingThread
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final mine = m.senderId == AppSession.currentUser?.id;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: mine ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
