enum Weekday {
  monday(1, 'Mon'),
  tuesday(2, 'Tue'),
  wednesday(3, 'Wed'),
  thursday(4, 'Thu'),
  friday(5, 'Fri'),
  saturday(6, 'Sat'),
  sunday(7, 'Sun');

  const Weekday(this.number, this.shortLabel);

  final int number;
  final String shortLabel;

  static Weekday fromDate(DateTime date) {
    return Weekday.values[date.weekday - 1];
  }

  static Weekday? fromNumber(int value) {
    for (final day in Weekday.values) {
      if (day.number == value) {
        return day;
      }
    }
    return null;
  }

  static Weekday? fromJson(dynamic value) {
    if (value is int) {
      return Weekday.fromNumber(value);
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      for (final day in Weekday.values) {
        if (day.name.toLowerCase() == normalized ||
            day.shortLabel.toLowerCase() == normalized) {
          return day;
        }
      }
    }
    return null;
  }
}
