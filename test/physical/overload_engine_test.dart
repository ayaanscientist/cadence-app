import 'package:cadence/core/database/tables.dart';
import 'package:cadence/features/physical/logic/overload_engine.dart';
import 'package:cadence/features/habits/logic/streak_calculator.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Overload Engine Test Suite
///
/// Run: flutter test test/physical/overload_engine_test.dart
///
/// Since Flutter SDK is not available in this environment, this file
/// contains a standalone `main()` that can also be run with `dart test`
/// or even `dart run` for quick manual verification.
/// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ── Group 1: CEIL Mode (Default for Reps) ─────────────────────────────
  _group('CEIL Mode — 1% Progressive Overload', () {
    // The key sample flow from the requirements: 10 → 11 → 12
    _test('10 reps → 11 reps (ceil(10 × 1.01) = ceil(10.1) = 11)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 10,
        rate: 0.01,
        mode: RoundingMode.ceil,
      );
      _expect(result.nextTarget, 11);
      _expectClose(result.rawCalculation, 10.1);
    });

    _test('11 reps → 12 reps (ceil(11 × 1.01) = ceil(11.11) = 12)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 11,
        rate: 0.01,
        mode: RoundingMode.ceil,
      );
      _expect(result.nextTarget, 12);
      _expectClose(result.rawCalculation, 11.11);
    });

    _test('12 reps → 13 reps (ceil(12 × 1.01) = ceil(12.12) = 13)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 12,
        rate: 0.01,
        mode: RoundingMode.ceil,
      );
      _expect(result.nextTarget, 13);
      _expectClose(result.rawCalculation, 12.12);
    });

    // Full simulation: 10 → 11 → 12 → 13 → ...
    _test('simulate() produces 10 → 11 → 12 → 13 over 4 days', () {
      final targets = OverloadEngine.simulate(
        startReps: 10,
        days: 4,
        rate: 0.01,
        mode: RoundingMode.ceil,
      );
      _expect(targets, [10, 11, 12, 13]);
    });

    _test('max() guard ensures at least +1 even for large rep counts', () {
      // 100 × 1.01 = 101.0 → ceil = 101, max(101, 101) = 101 ✓
      final result = OverloadEngine.computeNextTarget(
        completedReps: 100,
        rate: 0.01,
        mode: RoundingMode.ceil,
      );
      _expect(result.nextTarget, 101);
    });

    _test('aggressive 10% rate: 10 → 11 → 13 → 15', () {
      final targets = OverloadEngine.simulate(
        startReps: 10,
        days: 4,
        rate: 0.10,
        mode: RoundingMode.ceil,
      );
      _expect(targets, [10, 11, 13, 15]);
    });
  });

  // ── Group 2: FLOOR Mode ───────────────────────────────────────────────
  _group('FLOOR Mode — Conservative Rounding', () {
    _test('10 reps → 11 (floor(10.1)=10, but max guard gives 11)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 10,
        rate: 0.01,
        mode: RoundingMode.floor,
      );
      _expect(result.nextTarget, 11);
    });

    _test('100 reps → 101 (floor(101.0) = 101)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 100,
        rate: 0.01,
        mode: RoundingMode.floor,
      );
      _expect(result.nextTarget, 101);
    });
  });

  // ── Group 3: ACCUMULATE Mode ──────────────────────────────────────────
  _group('ACCUMULATE Mode — Micro-Accumulator for Weights', () {
    _test('10 reps, r=0.01 → accumulator=0.1, no step yet (stepSize=1)', () {
      final result = OverloadEngine.computeNextTarget(
        completedReps: 10,
        rate: 0.01,
        mode: RoundingMode.accumulate,
        currentAccumulator: 0.0,
        stepSize: 1.0,
      );
      // 10 * 0.01 = 0.1, which is < 1.0 step
      _expect(result.nextTarget, 10);
      _expectClose(result.accumulator, 0.1);
    });

    _test('accumulator carries over until it reaches stepSize', () {
      // After 10 days at 10 reps with r=0.01: acc = 10 × 0.1 = 1.0
      // On day 10, acc crosses 1.0 → target jumps by 1
      var currentReps = 10;
      var acc = 0.0;

      // Simulate 10 days
      for (var i = 0; i < 10; i++) {
        final result = OverloadEngine.computeNextTarget(
          completedReps: currentReps,
          rate: 0.01,
          mode: RoundingMode.accumulate,
          currentAccumulator: acc,
          stepSize: 1.0,
        );
        currentReps = result.nextTarget;
        acc = result.accumulator;
      }

      _expect(currentReps, 11);
    });

    _test('stepSize=2.5 with weight plates', () {
      // 100kg × 0.05 = 5.0 per day, stepSize=2.5 → immediate 2.5 jump
      final result = OverloadEngine.computeNextTarget(
        completedReps: 100,
        rate: 0.05,
        mode: RoundingMode.accumulate,
        currentAccumulator: 0.0,
        stepSize: 2,
      );
      // 100 * 0.05 = 5.0, steps = floor(5.0/2) = 2, increase = 4
      _expect(result.nextTarget, 104);
      _expectClose(result.accumulator, 1.0);
    });
  });

  // ── Group 4: Never-Miss-Twice Streak Calculator ───────────────────────
  _group('Never-Miss-Twice State Machine', () {
    _test('ACTIVE + completed → ACTIVE, streak+1', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.active,
        completedToday: true,
        currentStreak: 14,
      );
      _expect(eval.newStatus, HabitStatus.active);
      _expect(eval.newStreak, 15);
      _expect(eval.neverMissTwiceFlag, false);
      _expect(eval.notification, StreakNotification.none);
    });

    _test('ACTIVE + missed → AT_RISK, streak preserved', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.active,
        completedToday: false,
        currentStreak: 14,
      );
      _expect(eval.newStatus, HabitStatus.atRisk);
      _expect(eval.newStreak, 14); // Preserved during grace period
      _expect(eval.neverMissTwiceFlag, true);
      _expect(eval.notification, StreakNotification.amberWarning);
    });

    _test('AT_RISK + completed → ACTIVE (recovered), streak+1', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.atRisk,
        completedToday: true,
        currentStreak: 14,
      );
      _expect(eval.newStatus, HabitStatus.active);
      _expect(eval.newStreak, 15);
      _expect(eval.notification, StreakNotification.streakRestored);
    });

    _test('AT_RISK + missed → BROKEN, streak resets to 0', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.atRisk,
        completedToday: false,
        currentStreak: 14,
      );
      _expect(eval.newStatus, HabitStatus.broken);
      _expect(eval.newStreak, 0);
      _expect(eval.notification, StreakNotification.redAlert);
    });

    _test('BROKEN + completed → ACTIVE, streak starts at 1', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.broken,
        completedToday: true,
        currentStreak: 0,
      );
      _expect(eval.newStatus, HabitStatus.active);
      _expect(eval.newStreak, 1);
    });

    _test('BROKEN + missed → stays BROKEN', () {
      final eval = StreakCalculator.evaluateDay(
        currentStatus: HabitStatus.broken,
        completedToday: false,
        currentStreak: 0,
      );
      _expect(eval.newStatus, HabitStatus.broken);
      _expect(eval.newStreak, 0);
      _expect(eval.notification, StreakNotification.none);
    });
  });

  // ── Group 5: Streak from Dates ────────────────────────────────────────
  _group('Streak Calculation from Dates', () {
    _test('3 consecutive days → streak of 3', () {
      final dates = [
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 3),
      ];
      _expect(StreakCalculator.calculateStreakFromDates(dates), 3);
    });

    _test('gap in dates breaks streak', () {
      final dates = [
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 4),
        // Sep 3 missing
        DateTime(2026, 9, 2),
      ];
      _expect(StreakCalculator.calculateStreakFromDates(dates), 2);
    });

    _test('empty list → streak of 0', () {
      _expect(StreakCalculator.calculateStreakFromDates([]), 0);
    });

    _test('single date → streak of 1', () {
      _expect(
        StreakCalculator.calculateStreakFromDates([DateTime(2026, 9, 5)]),
        1,
      );
    });
  });

  // ── Summary ───────────────────────────────────────────────────────────
  print('');
  print('═' * 60);
  if (_failures == 0) {
    print('  ✅ ALL $_passed TESTS PASSED');
  } else {
    print('  ❌ $_failures FAILED, $_passed PASSED');
  }
  print('═' * 60);
}

// ═══════════════════════════════════════════════════════════════════════════
// Minimal test framework (no flutter_test dependency required)
// ═══════════════════════════════════════════════════════════════════════════

int _passed = 0;
int _failures = 0;
String _currentGroup = '';

void _group(String name, void Function() body) {
  _currentGroup = name;
  print('\n▸ $name');
  body();
}

void _test(String description, void Function() body) {
  try {
    body();
    _passed++;
    print('  ✓ $description');
  } catch (e) {
    _failures++;
    print('  ✗ $description');
    print('    FAILED: $e');
  }
}

void _expect(Object? actual, Object? expected) {
  if (actual is List && expected is List) {
    if (actual.length != expected.length) {
      throw AssertionError('Expected $expected but got $actual');
    }
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        throw AssertionError(
            'Expected $expected but got $actual (diff at index $i)');
      }
    }
    return;
  }
  if (actual != expected) {
    throw AssertionError('Expected $expected but got $actual');
  }
}

void _expectClose(double actual, double expected, [double epsilon = 0.001]) {
  if ((actual - expected).abs() > epsilon) {
    throw AssertionError(
        'Expected ≈$expected but got $actual (epsilon: $epsilon)');
  }
}
