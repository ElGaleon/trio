import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/shared/sport_filter_pill.dart';

class MatchDateFilters extends StatelessWidget {
  const MatchDateFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        SportFilterPill(
          icon: FIcons.calendar,
          label: startDate == null ? 'Da' : 'Da ${_dateLabel(startDate!)}',
          selected: startDate != null,
          onPressed: () async {
            final selected = await _pickDate(context, startDate);
            onStartChanged(selected);
          },
        ),
        SportFilterPill(
          icon: FIcons.calendar,
          label: endDate == null ? 'A' : 'A ${_dateLabel(endDate!)}',
          selected: endDate != null,
          onPressed: () async {
            final selected = await _pickDate(context, endDate);
            onEndChanged(selected);
          },
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
