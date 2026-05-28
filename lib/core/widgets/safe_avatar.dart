import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData placeholderIcon;

  const SafeAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.placeholderIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final shouldLoadNetworkImage =
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        !(kIsWeb && Uri.tryParse(imageUrl!)?.host == 'i.pravatar.cc');

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: shouldLoadNetworkImage
            ? Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  placeholderIcon,
                  size: radius,
                  color: AppColors.primary,
                ),
              )
            : Icon(placeholderIcon, size: radius, color: AppColors.primary),
      ),
    );
  }
}
