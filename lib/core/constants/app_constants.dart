/// Centralised application-wide constants for Cadence.
abstract final class AppConstants {
  // ── App Identity ──────────────────────────────────────────────────────
  static const String appName = 'Cadence';
  static const String appTagline = 'Your personal operating system.';

  // ── Progressive Overload Defaults ─────────────────────────────────────
  /// Default daily increment rate (1%).
  static const double defaultIncrementRate = 0.01;

  /// Minimum allowed increment rate.
  static const double minIncrementRate = 0.01;

  /// Maximum allowed increment rate (10%).
  static const double maxIncrementRate = 0.10;

  // ── Habit Engine ──────────────────────────────────────────────────────
  /// Hour:Minute at which the daily habit evaluation daemon runs (23:59:59).
  static const int habitEvalHour = 23;
  static const int habitEvalMinute = 59;

  // ── Mental / Meditation ───────────────────────────────────────────────
  /// Default meditation duration in seconds (15 minutes).
  static const int defaultMeditationDurationSeconds = 900;

  // ── Nutrition Defaults ────────────────────────────────────────────────
  static const int defaultCalorieTarget = 2400;
  static const int defaultProteinTargetGrams = 160;

  // ── Subjective Energy Score Range ─────────────────────────────────────
  static const int energyScoreMin = 1;
  static const int energyScoreMax = 5;

  // ── Founder Hub ───────────────────────────────────────────────────────
  /// Validation score range for business canvases.
  static const double validationScoreMin = 0.0;
  static const double validationScoreMax = 10.0;

  // ── Database ──────────────────────────────────────────────────────────
  static const String databaseFileName = 'cadence.sqlite';
  static const int databaseSchemaVersion = 1;
}
