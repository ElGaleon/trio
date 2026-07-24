import 'dart:io';
import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';
import 'sport_initials.dart';

class SportPlayerAvatar extends StatelessWidget {
  const SportPlayerAvatar({
    super.key,
    required this.initials,
    this.imagePath,
    this.size = 48,
    this.featured = false,
  });

  final String initials;
  final String? imagePath;
  final double size;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider(imagePath);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: featured ? 0.22 : 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: featured
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.12),
            width: featured ? 2 : 1,
          ),
          boxShadow: featured
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.30),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: image == null
              ? SportInitials(initials: initials)
              : Image(
                  image: image,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => SportInitials(initials: initials),
                ),
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}
