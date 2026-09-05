import 'package:cadence/core/database/tables.dart';

/// The "Never Miss Twice" Habit Streak Calculator.
///
/// Implements the state machine from the blueprint:
/// ```
/// [ ACTIVE ]
///      │
///      ▼ (Day 1 Missed)
/// [ AT_RISK ] ──► Amber Warning & Morning Priority Notification
///      │
///      ├──► (Day 2 Completed) ──► Return to [ ACTIVE ]
///      │
///      ▼ (Day 2 Missed)
/// [ BROKEN ]  ──► Red Notification & Reset Streak to 0
/// ```
///
/// Usage:
/// ```dart
/// final result = StreakCalculator.evaluateDay(
///   currentStatus: HabitStatus.active,
///   completedToday: false,
///   currentStreak: 14,
/// );
/// // result.newStatus == HabitStatus.atRisk
/// // result.newStreak == 14 (preserved during grace period)
/// // result.notification == StreakNotification.amberWarning
/// ```
class StreakCalculator {
  const StreakCalculator._();

  /// Evaluates a single day's outcome for a habit.
  ///
  /// Called by the daily 23:59:59 evaluation daemon for each habit.
  /// Returns a [StreakEvaluation] with the new state, streak count,
  /// and any notification that should be triggered.
  static StreakEvaluation evaluateDay({
    required HabitStatus currentStatus,
    required bool completedToday,
    required int currentStreak,
  }) {
    if (completedToday) {
      return _handleCompletion(currentStatus, currentStreak);
    } else {
      return _handleMiss(currentStatus, currentStreak);
    }
  }

  /// When the habit is completed:
  /// - Any state → ACTIVE
  /// - Streak increments by 1
  /// - No notification (or a positive "streak restored" if recovering from AT_RISK)
  static StreakEvaluation _handleCompletion(
    HabitStatus currentStatus,
    int currentStreak,
  ) {
    final notification = currentStatus == HabitStatus.atRisk
        ? StreakNotification.streakRestored
        : StreakNotification.none;

    return StreakEvaluation(
      newStatus: HabitStatus.active,
      newStreak: currentStreak + 1,
      neverMissTwiceFlag: false,
      notification: notification,
    );
  }

  /// When the habit is missed:
  /// - ACTIVE → AT_RISK (grace day — sets never_miss_twice_flag)
  /// - AT_RISK → BROKEN (streak resets to 0)
  /// - BROKEN → BROKEN (stays broken, streak stays 0)
  static StreakEvaluation _handleMiss(
    HabitStatus currentStatus,
    int currentStreak,
  ) {
    switch (currentStatus) {
      case HabitStatus.active:
        return StreakEvaluation(
          newStatus: HabitStatus.atRisk,
          newStreak: currentStreak, // Preserved during grace period.
          neverMissTwiceFlag: true,
          notification: StreakNotification.amberWarning,
        );

      case HabitStatus.atRisk:
        return const StreakEvaluation(
          newStatus: HabitStatus.broken,
          newStreak: 0,
          neverMissTwiceFlag: false,
          notification: StreakNotification.redAlert,
        );

      case HabitStatus.broken:
        return const StreakEvaluation(
          newStatus: HabitStatus.broken,
          newStreak: 0,
          neverMissTwiceFlag: false,
          notification: StreakNotification.none,
        );
    }
  }

  /// Calculates the streak from a list of completion dates.
  ///
  /// [completionDates] must be sorted newest-first (descending).
  /// Returns the number of consecutive days ending at today (or the most
  /// recent entry).
  static int calculateStreakFromDates(List<DateTime> completionDates) {
    if (completionDates.isEmpty) return 0;

    int streak = 1;
    for (var i = 0; i < completionDates.length - 1; i++) {
      final current = _stripTime(completionDates[i]);
      final previous = _stripTime(completionDates[i + 1]);
      final diff = current.difference(previous).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Strips time component, keeping only the date.
  static DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

/// The output of a streak evaluation for a single day.
class StreakEvaluation {
  const StreakEvaluation({
    required this.newStatus,
    required this.newStreak,
    required this.neverMissTwiceFlag,
    required this.notification,
  });

  final HabitStatus newStatus;
  final int newStreak;
  final bool neverMissTwiceFlag;
  final StreakNotification notification;

  @override
  String toString() =>
      'StreakEvaluation(status: $newStatus, streak: $newStreak, '
      'flag: $neverMissTwiceFlag, notification: $notification)';
}

/// Types of notifications triggered by streak state transitions.
enum StreakNotification {
  /// No notification needed.
  none,

  /// Amber warning: "You missed yesterday — don't miss again!"
  /// Triggers morning priority notification.
  amberWarning,

  /// Red alert: "Streak broken. Time to rebuild."
  /// Triggers system notification + streak reset.
  redAlert,

  /// Positive feedback: "Great recovery! Streak restored."
  streakRestored,
}
