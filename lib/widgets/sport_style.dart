import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../theme/app_colors.dart';

const sportMutedText = AppColors.sportMutedText;

class SportScreenShell extends StatefulWidget {
  const SportScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 18),
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;

  @override
  State<SportScreenShell> createState() => _SportScreenShellState();
}

class _SportScreenShellState extends State<SportScreenShell> {
  static const _minHeaderExtent = 72.0;
  static const _maxHeaderExtent = 108.0;

  late final ScrollController _scrollController;
  late final ValueNotifier<double> _headerProgress;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_syncHeaderProgress);
    _headerProgress = ValueNotifier<double>(0);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncHeaderProgress)
      ..dispose();
    _headerProgress.dispose();
    super.dispose();
  }

  void _syncHeaderProgress() {
    final range = _maxHeaderExtent - _minHeaderExtent;
    final progress = (_scrollController.offset / range).clamp(0.0, 1.0);
    if ((progress - _headerProgress.value).abs() > 0.01) {
      _headerProgress.value = progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.sportBackgroundEnd,
        systemNavigationBarDividerColor: AppColors.transparent,
      ),
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.25,
              colors: [
                AppColors.sportBackgroundStart,
                AppColors.sportBackgroundMid,
                AppColors.sportBackgroundEnd,
              ],
              stops: [0, 0.46, 1],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SportHeaderDelegate(
                            title: widget.title,
                            subtitle: widget.subtitle,
                            minHeaderExtent: _minHeaderExtent,
                            maxHeaderExtent: _maxHeaderExtent,
                          ),
                        ),
                        SliverPadding(
                          padding: widget.padding.add(
                            EdgeInsets.only(
                              bottom: widget.floatingActionButton == null
                                  ? 0
                                  : 76,
                            ),
                          ),
                          sliver: SliverToBoxAdapter(child: widget.child),
                        ),
                      ],
                    ),
                    if (widget.floatingActionButton != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: widget.floatingActionButton!,
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: safeTop,
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _headerProgress,
                    builder: (context, progress, child) {
                      return DecoratedBox(
                        decoration: _pinnedHeaderDecoration(
                          progress,
                          includeBorder: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SportHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
  });

  final String title;
  final String subtitle;
  final double minHeaderExtent;
  final double maxHeaderExtent;

  @override
  double get minExtent => minHeaderExtent;

  @override
  double get maxExtent => maxHeaderExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final textTheme = Theme.of(context).textTheme;
    final titleSize = 40 - (8 * progress);
    final actionSize = 44 - (6 * progress);
    final topPadding = 16 - (8 * progress);
    final bottomPadding = 12 - (4 * progress);
    return DecoratedBox(
      decoration: _pinnedHeaderDecoration(progress),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      heightFactor: 1 - progress,
                      alignment: AlignmentGeometry.centerLeft,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: sportMutedText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(AppRoutes.settings),
              child: Container(
                width: actionSize,
                height: actionSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SportHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        minHeaderExtent != oldDelegate.minHeaderExtent ||
        maxHeaderExtent != oldDelegate.maxHeaderExtent;
  }
}

BoxDecoration _pinnedHeaderDecoration(
  double progress, {
  bool includeBorder = true,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.sportHeaderDark.withValues(alpha: 0.92 * progress),
        AppColors.sportHeaderDark.withValues(alpha: 0.70 * progress),
      ],
    ),
    border: includeBorder
        ? Border(
            bottom: BorderSide(
              color: AppColors.violet.withValues(alpha: 0.22 * progress),
            ),
          )
        : null,
  );
}

class SportActionButton extends StatelessWidget {
  const SportActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = FIcons.plus,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.violet),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 16),
            const SizedBox(width: 6),
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

class SportFloatingActionButton extends StatelessWidget {
  const SportFloatingActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = FIcons.plus,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.violet,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.42),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class SportBackButton extends StatelessWidget {
  const SportBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.matches);
          }
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
          ),
          child: const Icon(
            FIcons.chevronLeft,
            color: AppColors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

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
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.white, size: 14),
              const SizedBox(width: 6),
            ],
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
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
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
            ? _Initials(initials: initials)
            : Image(
                image: image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(initials: initials),
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

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

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
