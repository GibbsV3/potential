enum Priority {
  veryLow(1, 'Very Low'),
  low(2, 'Low'),
  medium(3, 'Medium'),
  high(4, 'High'),
  veryHigh(5, 'Very High');

  const Priority(this.level, this.label);

  final int level;
  final String label;

  static Priority fromLevel(int? level) {
    if (level == null) {
      return Priority.medium;
    }
    for (final value in Priority.values) {
      if (value.level == level) {
        return value;
      }
    }
    return Priority.medium;
  }
}
