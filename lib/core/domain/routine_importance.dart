enum RoutineImportance {
  veryLow(1, 'Very Low'),
  low(2, 'Low'),
  medium(3, 'Medium'),
  high(4, 'High'),
  veryHigh(5, 'Very High');

  const RoutineImportance(this.level, this.label);

  final int level;
  final String label;

  static RoutineImportance fromLevel(int? level) {
    if (level == null) {
      return RoutineImportance.medium;
    }
    for (final value in RoutineImportance.values) {
      if (value.level == level) {
        return value;
      }
    }
    return RoutineImportance.medium;
  }
}
