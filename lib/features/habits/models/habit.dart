import 'package:equatable/equatable.dart';

import 'package:cadence/core/database/tables.dart';

/// Domain entity representing a single tracked habit.
///
/// Supports habit stacking (via [triggerHabitId]) and the
/// Never-Miss-Twice state machine (via [status]).
class Habit extends Equatable {

  /// Creates a [Habit] from a Drift-generated [HabitEntry] row.
  factory Habit.fromDb(dynamic row) {
    return Habit(
      id: row.id as String,
      title: row.title as String,
      triggerHabitId: row.triggerHabitId as String?,
      stackFormula: row.stackFormula as String?,
      targetFrequency: _parseFrequency(row.targetFrequency as String),
      createdAt: row.createdAt as DateTime,
      currentStreak: row.currentStreak as int,
      status: _parseStatus(row.statusState as String),
      neverMissTwiceFlag: row.neverMissTwiceFlag as bool,
      lastCompletedTimestamp: row.lastCompletedTimestamp as DateTime?,
    );
  }
  const Habit({
    required this.id,
    required this.title,
    this.triggerHabitId,
    this.stackFormula,
    this.targetFrequency = HabitFrequency.daily,
    required this.createdAt,
    this.currentStreak = 0,
    this.status = HabitStatus.active,
    this.neverMissTwiceFlag = false,
    this.lastCompletedTimestamp,
  });

  final String id;
  final String title;

  /// When non-null, this habit is part of a stack and fires
  /// after the habit with this ID is completed.
  final String? triggerHabitId;

  /// Human-readable stack description:
  /// "After I complete Meditation, I will do 20m Business Planning"
  final String? stackFormula;

  final HabitFrequency targetFrequency;
  final DateTime createdAt;
  final int currentStreak;
  final HabitStatus status;

  /// `true` when the user missed yesterday — they have one grace day
  /// before the streak breaks.
  final bool neverMissTwiceFlag;

  final DateTime? lastCompletedTimestamp;

  // ── Computed properties ─────────────────────────────────────────────

  /// Whether this habit is chained after another habit.
  bool get isStacked => triggerHabitId != null;

  /// Whether the streak is in danger (one more miss = broken).
  bool get isAtRisk => status == HabitStatus.atRisk;

  // ── Serialisation helpers ───────────────────────────────────────────

  static HabitFrequency _parseFrequency(String value) {
    return HabitFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => HabitFrequency.daily,
    );
  }

  static HabitStatus _parseStatus(String value) {
    return HabitStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => HabitStatus.active,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        triggerHabitId,
        stackFormula,
        targetFrequency,
        createdAt,
        currentStreak,
        status,
        neverMissTwiceFlag,
        lastCompletedTimestamp,
      ];

  @override
  String toString() => 'Habit($title, streak: $currentStreak, status: $status)';
}
