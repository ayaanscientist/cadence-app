import 'package:cadence/features/physical/logic/biometric_calculator.dart';

void main() {
  _group('Mifflin-St Jeor BMR Calculations', () {
    _test('Male BMR calculation: 80kg, 180cm, 25yrs', () {
      // (10 * 80) + (6.25 * 180) - (5 * 25) + 5 = 800 + 1125 - 125 + 5 = 1805
      final bmr = BiometricCalculator.calculateBmr(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 25,
        gender: 'male',
      );
      _expect(bmr, 1805.0);
    });

    _test('Female BMR calculation: 60kg, 165cm, 30yrs', () {
      // (10 * 60) + (6.25 * 165) - (5 * 30) - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      final bmr = BiometricCalculator.calculateBmr(
        weightKg: 60.0,
        heightCm: 165.0,
        age: 30,
        gender: 'female',
      );
      _expect(bmr, 1320.25);
    });
  });

  _group('Activity Multipliers & TDEE Calculations', () {
    _test('Sedentary activity multiplier (1.2x)', () {
      _expect(BiometricCalculator.activityMultiplier('sedentary'), 1.2);
      final tdee = BiometricCalculator.calculateTdee(
        bmr: 1800.0,
        activityLevel: 'sedentary',
      );
      _expect(tdee, 2160.0);
    });

    _test('Moderate activity multiplier (1.55x)', () {
      _expect(BiometricCalculator.activityMultiplier('moderate'), 1.55);
      final tdee = BiometricCalculator.calculateTdee(
        bmr: 1800.0,
        activityLevel: 'moderate',
      );
      _expect(tdee, 2790.0);
    });
  });

  _group('Calorie Goal Adjustments', () {
    _test('Fat loss creates 500 kcal deficit', () {
      final calories = BiometricCalculator.calculateTargetCalories(
        tdee: 2500.0,
        goal: 'fatLoss',
      );
      _expect(calories, 2000);
    });

    _test('Maintenance equals TDEE', () {
      final calories = BiometricCalculator.calculateTargetCalories(
        tdee: 2500.0,
        goal: 'maintenance',
      );
      _expect(calories, 2500);
    });

    _test('Muscle gain creates 300 kcal surplus', () {
      final calories = BiometricCalculator.calculateTargetCalories(
        tdee: 2500.0,
        goal: 'muscleGain',
      );
      _expect(calories, 2800);
    });
  });

  _group('Protein Target Calculations', () {
    _test('80kg bodyweight @ 1.8g/kg = 144g protein', () {
      final protein = BiometricCalculator.calculateProteinTarget(
        weightKg: 80.0,
        gramsPerKg: 1.8,
      );
      _expect(protein, 144);
    });

    _test('65kg bodyweight @ 1.8g/kg = 117g protein', () {
      final protein = BiometricCalculator.calculateProteinTarget(
        weightKg: 65.0,
        gramsPerKg: 1.8,
      );
      _expect(protein, 117);
    });
  });

  _group('Dynamic Sleep Debt Engine', () {
    _test('Daily sleep debt calculation (8.0h target - 6.5h actual = 1.5h debt)', () {
      final debt = BiometricCalculator.calculateDailySleepDebt(
        targetSleepHours: 8.0,
        actualSleepHours: 6.5,
      );
      _expect(debt, 1.5);
    });

    _test('Rolling 7-day sleep debt accumulation', () {
      final debts = [1.0, 0.5, 2.0, 0.0, 1.5, 0.0, 1.0]; // Total = 6.0 hours debt
      final rollingDebt = BiometricCalculator.calculateRollingSleepDebt(debts);
      _expect(rollingDebt, 6.0);

      final assessment = BiometricCalculator.assessSleepDebt(rollingDebt);
      _expect(assessment.level, SleepDebtLevel.critical);
    });

    _test('Optimal sleep debt assessment for <= 1.0h', () {
      final debts = [0.0, 0.5, 0.0, 0.0, 0.0, 0.5, 0.0]; // Total = 1.0 hour
      final rollingDebt = BiometricCalculator.calculateRollingSleepDebt(debts);
      _expect(rollingDebt, 1.0);

      final assessment = BiometricCalculator.assessSleepDebt(rollingDebt);
      _expect(assessment.level, SleepDebtLevel.optimal);
    });
  });

  _printSummary();
}

int _passed = 0;
int _failed = 0;
String _currentGroup = '';

void _group(String name, void Function() body) {
  _currentGroup = name;
  // ignore: avoid_print
  print('\n=== $name ===');
  body();
}

void _test(String name, void Function() body) {
  try {
    body();
    _passed++;
    // ignore: avoid_print
    print('  [PASS] $name');
  } catch (e) {
    _failed++;
    // ignore: avoid_print
    print('  [FAIL] $name: $e');
  }
}

void _expect(dynamic actual, dynamic expected) {
  if (actual != expected) {
    throw Exception('Expected $expected but got $actual (in $_currentGroup)');
  }
}

void _printSummary() {
  // ignore: avoid_print
  print('\n----------------------------------------');
  // ignore: avoid_print
  print('BiometricCalculator Tests: $_passed passed, $_failed failed');
  // ignore: avoid_print
  print('----------------------------------------');
}
