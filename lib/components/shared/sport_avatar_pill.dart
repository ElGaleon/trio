import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SportFilterPill extends StatelessWidget {
  const SportFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.24)
              : AppColors.white.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (icon != null) Icon(icon, color: AppColors.white, size: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class SportInitials extends StatelessWidget {
  const SportInitials({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

BoxDecoration sportGlassDecoration({Gradient? gradient, double radius = 28}) {
  return BoxDecoration(
    color: AppColors.white.withValues(alpha: 0.07),
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.white.withValues(alpha: 0.13)),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.24),
        blurRadius: 28,
        offset: const Offset(0, 18),
      ),
    ],
  );
}
