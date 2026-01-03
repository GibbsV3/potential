String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

List<DateTime> weekDates(DateTime selected) {
  final normalized = DateTime(selected.year, selected.month, selected.day);
  final weekdayIndexFromSunday = normalized.weekday % 7;
  final start = normalized.subtract(Duration(days: weekdayIndexFromSunday));
  return List<DateTime>.generate(
    7,
    (index) => DateTime(start.year, start.month, start.day + index),
  );
}
