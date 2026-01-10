class AppMotion {
  const AppMotion._();

  // Subtle, spring-like timings aligned with iOS feel.
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration relaxed = Duration(milliseconds: 300);
}
