import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/shared/responsive_layout.dart';
import 'package:trio/src/theme/app_colors.dart';

const sportMutedText = AppColors.sportMutedText;

class SportScreenShell extends StatefulWidget {
  const SportScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 18),
    this.floatingActionButton,
    this.showBackButton = false,
    this.headerActions,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final List<Widget>? headerActions;

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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final showFloatingInHeader = kIsWeb && widget.floatingActionButton != null;
    final floatingActionButton = showFloatingInHeader
        ? null
        : widget.floatingActionButton;
    final headerActions = [
      ...?widget.headerActions,
      if (showFloatingInHeader) widget.floatingActionButton!,
    ];
    final floatingInset = floatingActionButton == null ? 0.0 : 76.0;
    final horizontalPadding = size.width >= ResponsiveLayout.desktop
        ? 32.0
        : size.width >= ResponsiveLayout.tablet
        ? 24.0
        : 16.0;
    final resolvedPadding = widget.padding.resolve(Directionality.of(context));
    final contentPadding = resolvedPadding.copyWith(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: resolvedPadding.bottom + floatingInset + keyboardInset + 24,
    );
    final contentWidth = size.width.clamp(
      0.0,
      ResponsiveLayout.contentMaxWidth,
    );
    final floatingRight =
        ((size.width - contentWidth) / 2).clamp(0.0, double.infinity) +
        horizontalPadding;
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          automaticallyImplyLeading: false,
                          backgroundColor: AppColors.transparent,
                          surfaceTintColor: AppColors.transparent,
                          elevation: 0,
                          toolbarHeight: _minHeaderExtent,
                          collapsedHeight: _minHeaderExtent,
                          expandedHeight: _maxHeaderExtent,
                          flexibleSpace: LayoutBuilder(
                            builder: (context, constraints) {
                              final range = _maxHeaderExtent - _minHeaderExtent;
                              final currentHeight = constraints.biggest.height;
                              final progress =
                                  ((_maxHeaderExtent - currentHeight) / range)
                                      .clamp(0.0, 1.0);
                              return SportHeaderContent(
                                title: widget.title,
                                subtitle: widget.subtitle,
                                progress: progress,
                                showBackButton: widget.showBackButton,
                                actions: headerActions,
                              );
                            },
                          ),
                        ),
                        SliverPadding(
                          padding: contentPadding,
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: ResponsiveLayout.contentMaxWidth,
                                ),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (floatingActionButton != null)
                      Positioned(
                        right: floatingRight,
                        bottom: 16 + keyboardInset,
                        child: floatingActionButton,
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
                        decoration: pinnedHeaderDecoration(
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

class SportHeaderContent extends StatelessWidget {
  const SportHeaderContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.showBackButton,
    this.actions,
  });

  final String title;
  final String subtitle;
  final double progress;
  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleSize = 40 - (8 * progress);
    final actionSize = 44 - (6 * progress);
    final topPadding = 16 - (8 * progress);
    final bottomPadding = 12 - (4 * progress);
    return DecoratedBox(
      decoration: pinnedHeaderDecoration(progress),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ResponsiveLayout.contentMaxWidth + 64,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
            child: Row(
              spacing: 10,
              children: [
                if (showBackButton)
                  HeaderIconButton(
                    size: actionSize,
                    icon: FIcons.chevronLeft,
                    tooltip: 'Indietro',
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.matches);
                      }
                    },
                  ),
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
                      Opacity(
                        opacity: 1 - (progress * 0.75),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: sportMutedText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SportHeaderDelegate extends SliverPersistentHeaderDelegate {
  const SportHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
    required this.showBackButton,
  });

  final String title;
  final String subtitle;
  final double minHeaderExtent;
  final double maxHeaderExtent;
  final bool showBackButton;

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
      decoration: pinnedHeaderDecoration(progress),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
        child: Row(
          spacing: 10,
          children: [
            if (showBackButton)
              HeaderIconButton(
                size: actionSize,
                icon: FIcons.chevronLeft,
                tooltip: 'Indietro',
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.matches);
                  }
                },
              ),
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
                      alignment: Alignment.centerLeft,
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
            HeaderIconButton(
              size: actionSize,
              icon: Icons.settings_outlined,
              tooltip: 'Impostazioni',
              onTap: () => context.go(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SportHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        minHeaderExtent != oldDelegate.minHeaderExtent ||
        maxHeaderExtent != oldDelegate.maxHeaderExtent ||
        showBackButton != oldDelegate.showBackButton;
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.white, size: 21),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration pinnedHeaderDecoration(
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
