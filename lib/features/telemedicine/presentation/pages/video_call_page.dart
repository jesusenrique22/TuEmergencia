import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/domain/models/role.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _showChat = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'sender': 'Dr. Aristhène', 'text': 'Hola Juan, ¿cómo has seguido?'},
  ];

  bool get _isDoctor => AppSession.activeRole == Role.doctor;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientName =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Juan Pérez';
    final remoteName = _isDoctor ? patientName : 'Dr. Aristhène';
    final remoteSubtitle = _isDoctor
        ? 'Paciente • Consulta en curso'
        : 'Cardiología • Consulta en curso';
    final pipLabel = _isDoctor ? 'Tú' : 'Tú';

    return ResponsiveScaffold(
      title: const Text('Video Llamada'),
      hideNavigation: true,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Main remote video (mocked by role).
          Positioned.fill(child: _buildRemoteVideo(patientName)),
          // Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // Top Info Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remoteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      remoteSubtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.signal_cellular_alt,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
          ),
          // Local camera preview.
          Positioned(
            top: 110,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showChat ? 0.3 : 1.0,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildLocalPreview(pipLabel),
                ),
              ),
            ),
          ),
          // Chat Overlay
          if (_showChat) _buildChatOverlay(),
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white24,
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  iconSize: 32,
                  onPressed: () => AppNavigation.safeBack(context),
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: _isCameraOff ? Colors.red : Colors.white24,
                  onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.chat_bubble_outline,
                  color: _showChat ? AppColors.primary : Colors.white24,
                  onPressed: () => setState(() => _showChat = !_showChat),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo(String patientName) {
    if (!_isDoctor) {
      return Image.network(
        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=1000',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildRemotePlaceholder(
          label: 'Dr. Aristhène',
          icon: Icons.medical_services_rounded,
        ),
      );
    }

    return _buildRemotePlaceholder(
      label: patientName,
      icon: Icons.person_rounded,
      subtitle: 'Cámara del paciente',
    );
  }

  Widget _buildRemotePlaceholder({
    required String label,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 58,
              backgroundColor: Colors.white24,
              child: Icon(icon, color: Colors.white, size: 58),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPreview(String label) {
    if (_isCameraOff) {
      return Container(
        color: Colors.grey.shade900,
        child: const Icon(Icons.videocam_off, color: Colors.white54),
      );
    }

    return Container(
      color: AppColors.primaryLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDoctor ? Icons.medical_services_rounded : Icons.person_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      bottom: 130,
      left: 20,
      right: 20,
      top: 150,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Chat de Consulta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showChat = false),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'Yo';
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary : Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg['sender']!,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            msg['text']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          setState(() {
                            _messages.add({
                              'sender': 'Yo',
                              'text': _messageController.text,
                            });
                            _messageController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double iconSize = 24,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Backdrop filter logic should be outside or handled differently
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
