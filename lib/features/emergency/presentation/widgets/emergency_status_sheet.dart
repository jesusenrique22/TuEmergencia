import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_avatar.dart';

class EmergencyStatusSheet extends StatelessWidget {
  final String statusLabel;
  final int etaMinutes;
  final String driverName;
  final String unitLabel;
  final String? profilePic;
  final bool cancelling;
  final VoidCallback? onCall;
  final VoidCallback? onCancel;

  const EmergencyStatusSheet({
    super.key,
    required this.statusLabel,
    required this.etaMinutes,
    required this.driverName,
    required this.unitLabel,
    this.profilePic,
    this.cancelling = false,
    this.onCall,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = statusLabel.toLowerCase().contains('buscando');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pull handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Status Title
          Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          if (isSearching) ...[
            // Premium radar ripple loader
            const RadarRippleLoader(),
            const SizedBox(height: 12),
            const Text(
              'Buscando conductor cercano...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enviando señal de emergencia a las ambulancias en tu zona.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Sleek loading line
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                height: 4,
                width: 140,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emergency),
                ),
              ),
            ),
          ] else ...[
            // Standard ETA badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Llegada en $etaMinutes minutos',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Driver information row
            Row(
              children: [
                SafeAvatar(radius: 28, imageUrl: profilePic),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Unidad $unitLabel',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                    onPressed: onCall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: cancelling ? null : onCancel,
              child: cancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Text('Cancelar solicitud'),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarRippleLoader extends StatefulWidget {
  const RadarRippleLoader({super.key});

  @override
  State<RadarRippleLoader> createState() => _RadarRippleLoaderState();
}

class _RadarRippleLoaderState extends State<RadarRippleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Ripple 2
                _buildRipple(
                  (1.0 - _controller.value).clamp(0.0, 1.0),
                  70 + _controller.value * 80,
                ),
                // Ripple 1
                _buildRipple(
                  ((1.0 - _controller.value) * 0.7).clamp(0.0, 1.0),
                  50 + _controller.value * 50,
                ),
                // Central core
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRipple(double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEF4444).withValues(alpha: opacity),
      ),
    );
  }
}
