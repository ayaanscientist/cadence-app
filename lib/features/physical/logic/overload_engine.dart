import 'dart:math';

import 'package:cadence/core/database/tables.dart';
import 'package:cadence/features/physical/models/exercise_target.dart';

/// The Dynamic 1% Progressive Overload Engine.
///
/// Calculates the next-day target reps/weight based on the user's
/// completed reps and their configured growth rate [r].
///
/// Three rounding modes are supported:
///
/// ### CEIL (Default for Repetitions)
/// ```
/// R_t = max(R_{t-1} + 1, ⌈R_{t-1} × (1 + r)⌉)
/// ```
/// Guarantees at least +1 rep per successful day. The ceiling ensures
/// fractional results always round up (e.g., 10 × 1.01 = 10.1 → 11).
///
/// ### FLOOR (Conservative)
/// ```
/// R_t = max(R_{t-1} + 1, ⌊R_{t-1} × (1 + r)⌋)
/// ```
/// Rounds down — more conservative for recovery-focused programming.
/// Still guarantees at least +1 via the max() guard.
///
/// ### ACCUMULATE (Continuous Micro-Accumulator for Weights/Distance)
/// ```
/// A_t = A_{t-1} + (R_{t-1} × r)
/// target = W_base + ⌊A_t / stepSize⌋ × stepSize
/// ```
/// Tracks fractional remainders across days so that sub-unit
/// increments eventually compound into whole-unit jumps.
class OverloadEngine {
  const OverloadEngine._();

  /// Computes the next target given today's completed reps.
  ///
  /// Returns a [ProgressionResult] containing the new target and
  /// updated accumulator (relevant only for ACCUMULATE mode).
  ///
  /// [completedReps] — reps the user actually completed today.
  /// [rate] — growth percentage (default 0.01 = 1%).
  /// [mode] — rounding strategy.
  /// [currentAccumulator] — running fractional accumulator (ACCUMULATE mode).
  /// [stepSize] — minimum increment unit for ACCUMULATE mode (e.g., 2.5 kg).
  static ProgressionResult computeNextTarget({
    required int completedReps,
    double rate = 0.01,
    RoundingMode mode = RoundingMode.ceil,
    double currentAccumulator = 0.0,
    double stepSize = 1.0,
  }) {
    assert(completedReps > 0, 'completedReps must be positive');
    assert(rate > 0 && rate <= 1.0, 'rate must be in (0, 1.0]');
    assert(stepSize > 0, 'stepSize must be positive');

    switch (mode) {
      case RoundingMode.ceil:
        return _computeCeil(completedReps, rate);

      case RoundingMode.floor:
        return _computeFloor(completedReps, rate);

      case RoundingMode.accumulate:
        return _computeAccumulate(
          completedReps,
          rate,
          currentAccumulator,
          stepSize,
        );
    }
  }

  /// Applies the full progression to an [ExerciseTarget] entity,
  /// returning an updated copy with the new currentReps and accumulator.
  static ExerciseTarget applyProgression({
    required ExerciseTarget target,
    required int completedReps,
    double stepSize = 1.0,
  }) {
    final result = computeNextTarget(
      completedReps: completedReps,
      rate: target.incrementRate,
      mode: target.roundingMode,
      currentAccumulator: target.fractionalAccumulator,
      stepSize: stepSize,
    );

    return target.copyWith(
      currentReps: result.nextTarget.toDouble(),
      fractionalAccumulator: result.accumulator,
    );
  }

  // ── Private Mode Implementations ────────────────────────────────────

  /// CEIL mode: R_t = max(R_{t-1} + 1, ⌈R_{t-1} × (1 + r)⌉)
  static ProgressionResult _computeCeil(int completedReps, double rate) {
    final raw = completedReps * (1 + rate);
    final ceiled = raw.ceil();
    final nextTarget = max(completedReps + 1, ceiled);

    return ProgressionResult(
      nextTarget: nextTarget,
      rawCalculation: raw,
      accumulator: 0.0,
    );
  }

  /// FLOOR mode: R_t = max(R_{t-1} + 1, ⌊R_{t-1} × (1 + r)⌋)
  static ProgressionResult _computeFloor(int completedReps, double rate) {
    final raw = completedReps * (1 + rate);
    final floored = raw.floor();
    final nextTarget = max(completedReps + 1, floored);

    return ProgressionResult(
      nextTarget: nextTarget,
      rawCalculation: raw,
      accumulator: 0.0,
    );
  }

  /// ACCUMULATE mode:
  ///   A_t = A_{t-1} + (R_{t-1} × r)
  ///   steps = ⌊A_t / stepSize⌋
  ///   target = R_{t-1} + steps * stepSize
  ///   A_t = A_t - steps * stepSize  (carry remainder)
  static ProgressionResult _computeAccumulate(
    int completedReps,
    double rate,
    double currentAccumulator,
    double stepSize,
  ) {
    final increment = completedReps * rate;
    var newAccumulator = currentAccumulator + increment;

    final steps = (newAccumulator / stepSize).floor();
    final targetIncrease = steps * stepSize;
    newAccumulator -= targetIncrease;

    final nextTarget = completedReps + targetIncrease.toInt();

    return ProgressionResult(
      nextTarget: nextTarget,
      rawCalculation: completedReps + increment,
      accumulator: newAccumulator,
    );
  }

  /// Runs a multi-day simulation starting from [startReps].
  ///
  /// Returns a list of daily targets for [days] consecutive successful days.
  /// Useful for previewing long-term progression curves in the UI.
  static List<int> simulate({
    required int startReps,
    required int days,
    double rate = 0.01,
    RoundingMode mode = RoundingMode.ceil,
    double stepSize = 1.0,
  }) {
    final targets = <int>[startReps];
    var currentReps = startReps;
    var accumulator = 0.0;

    for (var day = 1; day < days; day++) {
      final result = computeNextTarget(
        completedReps: currentReps,
        rate: rate,
        mode: mode,
        currentAccumulator: accumulator,
        stepSize: stepSize,
      );
      targets.add(result.nextTarget);
      currentReps = result.nextTarget;
      accumulator = result.accumulator;
    }

    return targets;
  }
}

/// The output of a single progression calculation.
class ProgressionResult {
  const ProgressionResult({
    required this.nextTarget,
    required this.rawCalculation,
    required this.accumulator,
  });

  /// The next day's target (integer).
  final int nextTarget;

  /// The unrounded calculation result (for transparency / debugging).
  final double rawCalculation;

  /// Updated fractional accumulator (only meaningful for ACCUMULATE mode).
  final double accumulator;

  @override
  String toString() =>
      'ProgressionResult(next: $nextTarget, raw: $rawCalculation, acc: $accumulator)';
}
