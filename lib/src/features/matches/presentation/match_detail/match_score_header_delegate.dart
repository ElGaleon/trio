import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/shared/match_card.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'compact_match_title.dart';

class MatchScoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  const MatchScoreHeaderDelegate({required this.match});

  final ScrimmageMatch match;

  static const _minBase = 132.0;
  static const _maxBase = 292.0;

  @override
  double get minExtent => _minBase + 0;

  @override
  double get maxExtent => _maxBase;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final safeTop = MediaQuery.paddingOf(context).top;
    final compact = progress > 0.52;
    final showExpanded = progress < 0.82;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportHeaderDark.withValues(
          alpha: 0.84 + (0.14 * progress),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.white.withValues(alpha: 0.08 + 0.08 * progress),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, safeTop + 8, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                HeaderIconButton(
                  size: 44 - (6 * progress),
                  icon: FIcons.chevronLeft,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.matches);
                    }
                  },
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: compact ? 1 : 0,
                    child: CompactMatchTitle(match: match),
                  ),
                ),
                HeaderIconButton(
                  size: 44 - (6 * progress),
                  icon: FIcons.star,
                  onTap: () {},
                ),
              ],
            ),
            if (showExpanded)
              Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    minHeight: 0,
                    maxHeight: 240,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: (1 - (progress / 0.82)).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -10 * progress),
                        child: Center(
                          child: Hero(
                            tag: matchHeroTag(match.id),
                            child: MatchScoreHeroPanel(
                              match: match,
                              framed: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant MatchScoreHeaderDelegate oldDelegate) {
    return match != oldDelegate.match;
  }
}
