class CalendarUtils {
  const CalendarUtils._();

  static List<DateTime> calendarDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final firstOffset = first.weekday - DateTime.monday;
    final start = first.subtract(Duration(days: firstOffset));
    return [for (var i = 0; i < 42; i++) start.add(Duration(days: i))];
  }

  static bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  static String weekdayShort(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  static String monthLabel(DateTime date) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return months[date.month - 1];
  }

  static String dayLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
