import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'pull_draft.dart';
import 'pull_stopwatch_sheet.dart';

class PullSheet {
  const PullSheet._();

  static Future<PullDraft?> show(
    BuildContext context,
    List<Player> players,
  ) async {
    return showModalBottomSheet<PullDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => PullStopwatchSheet(players: players),
    );
  }
}
