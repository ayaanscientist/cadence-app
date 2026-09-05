import 'package:equatable/equatable.dart';

import 'package:cadence/core/database/tables.dart';

/// Domain entity for an exercise with progressive overload tracking.
///
/// The overload formula computes tomorrow's target from today's completed reps
/// and the user-configurable [incrementRate] (default 1%).
class ExerciseTarget extends Equatable {

  factory ExerciseTarget.fromDb(dynamic row) {
    return ExerciseTarget(
      id: row.id as String,
      exerciseName: row.exerciseName as String,
      baseReps: row.baseReps as double,
      currentReps: row.currentReps as double,
      incrementRate: row.incrementRate as double,
      roundingMode: _parseMode(row.roundingMode as String),
      fractionalAccumulator: row.fractionalAccumulator as double,
      createdAt: row.createdAt as DateTime?,
    );
  }
  const ExerciseTarget({
    required this.id,
    required this.exerciseName,
    required this.baseReps,
    required this.currentReps,
    this.incrementRate = 0.01,
    this.roundingMode = RoundingMode.ceil,
    this.fractionalAccumulator = 0.0,
    this.createdAt,
  });

  final String id;
  final String exerciseName;

  /// The original baseline reps when first created.
  final double baseReps;

  /// Current target reps (may be fractional internally for ACCUMULATE mode).
  final double currentReps;

  /// Growth percentage per successful day. Default 0.01 (1%).
  /// Constrained to [0.01, 0.10].
  final double incrementRate;

  /// Strategy for converting fractional targets to whole numbers.
  final RoundingMode roundingMode;

  /// Running sub-unit accumulator (used only in ACCUMULATE mode).
  final double fractionalAccumulator;

  final DateTime? createdAt;

  // ── Computed ─────────────────────────────────────────────────────────

  /// The display-ready integer target (ceiling of currentReps).
  int get displayTarget => currentReps.ceil();

  /// Days since the exercise was created (proxy for progression length).
  int get daysSinceCreation {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt!).inDays;
  }

  // ── Serialisation ───────────────────────────────────────────────────

  static RoundingMode _parseMode(String value) {
    return RoundingMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => RoundingMode.ceil,
    );
  }

  /// Returns a copy with updated rep fields after progression.
  ExerciseTarget copyWith({
    double? currentReps,
    double? fractionalAccumulator,
  }) {
    return ExerciseTarget(
      id: id,
      exerciseName: exerciseName,
      baseReps: baseReps,
      currentReps: currentReps ?? this.currentReps,
      incrementRate: incrementRate,
      roundingMode: roundingMode,
      fractionalAccumulator:
          fractionalAccumulator ?? this.fractionalAccumulator,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        exerciseName,
        baseReps,
        currentReps,
        incrementRate,
        roundingMode,
        fractionalAccumulator,
        createdAt,
      ];

  @override
  String toString() =>
      'ExerciseTarget($exerciseName, target: $displayTarget, rate: $incrementRate)';
}
