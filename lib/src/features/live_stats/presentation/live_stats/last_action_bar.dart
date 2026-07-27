import 'package:flutter/material.dart';

import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player.dart';

class LastActionBar extends StatelessWidget {
  const LastActionBar({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final event = match.statEvents.isEmpty ? null : match.statEvents.last;
    final textTheme = Theme.of(context).textTheme;
    final author = event?.createdByLabel?.trim();
    final label = event == null
        ? 'Nessuna azione registrata'
        : author == null || author.isEmpty
        ? event.description ?? event.type.label
        : '${event.description ?? event.type.label} · da $author';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.sportForeground(context).withValues(alpha: 0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.sportMutedForeground(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
