/// Pure mathematical calculation engine for Basal Metabolic Rate (BMR),
/// Total Daily Energy Expenditure (TDEE), protein targets, and sleep debt.
class BiometricCalculator {
  const BiometricCalculator._();

  // ── 1. BMR (Mifflin-St Jeor Formula) ──────────────────────────────────

  /// Calculates Basal Metabolic Rate in kcal using the Mifflin-St Jeor equation.
  ///
  /// Men:   BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
  /// Women: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    if (gender.toLowerCase() == 'female') {
      return base - 161.0;
    }
    // Default to male equation (+5)
    return base + 5.0;
  }

  // ── 2. Activity Multipliers & TDEE ────────────────────────────────────

  /// Physical activity level multiplier based on weekly exercise frequency.
  static double activityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Little to no exercise, desk job
      case 'light':
        return 1.375; // Light exercise 1-3 days/week
      case 'moderate':
        return 1.55; // Moderate exercise 3-5 days/week
      case 'active':
        return 1.725; // Hard exercise 6-7 days/week
      case 'veryactive':
      case 'very_active':
        return 1.9; // Physical labor or elite athletic training
      default:
        return 1.55;
    }
  }

  /// Calculates Total Daily Energy Expenditure (maintenance calories).
  static double calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    return bmr * activityMultiplier(activityLevel);
  }

  // ── 3. Calorie Goal Adjustments ───────────────────────────────────────

  /// Computes target daily calorie intake based on the user's primary body goal.
  ///
  /// - `fatLoss`: 500 kcal deficit (~0.5 kg fat loss/week)
  /// - `maintenance`: equal to TDEE
  /// - `muscleGain`: 300 kcal lean bulk surplus
  static int calculateTargetCalories({
    required double tdee,
    required String goal,
  }) {
    switch (goal.toLowerCase()) {
      case 'fatloss':
      case 'fat_loss':
        return (tdee - 500.0).round().clamp(1200, 6000);
      case 'musclegain':
      case 'muscle_gain':
        return (tdee + 300.0).round();
      case 'maintenance':
      default:
        return tdee.round();
    }
  }

  // ── 4. Protein Target ─────────────────────────────────────────────────

  /// Calculates optimal daily protein target in grams.
  ///
  /// Default standard is 1.8g per kg bodyweight for lean tissue preservation
  /// and progressive overload muscle repair.
  static int calculateProteinTarget({
    required double weightKg,
    double gramsPerKg = 1.8,
  }) {
    return (weightKg * gramsPerKg).round();
  }

  // ── 5. Dynamic Sleep Debt Engine ──────────────────────────────────────

  /// Calculates single-day sleep debt in hours.
  ///
  /// Positive value indicates a sleep deficit (e.g. +1.5 hours owed).
  /// Negative value indicates surplus/recovery sleep.
  static double calculateDailySleepDebt({
    required double targetSleepHours,
    required double actualSleepHours,
  }) {
    return (targetSleepHours - actualSleepHours);
  }

  /// Calculates cumulative rolling 7-day sleep debt from daily hour records.
  static double calculateRollingSleepDebt(List<double> dailyDebts) {
    if (dailyDebts.isEmpty) return 0.0;
    // Sum the most recent up to 7 entries
    final recent = dailyDebts.length > 7
        ? dailyDebts.sublist(dailyDebts.length - 7)
        : dailyDebts;
    final total = recent.fold<double>(0.0, (sum, debt) => sum + debt);
    // Don't accumulate negative infinity; floor at 0 for debt accumulation
    return total < 0.0 ? 0.0 : total;
  }

  /// Evaluates sleep recovery advice based on cumulative rolling debt.
  static SleepDebtAssessment assessSleepDebt(double rollingDebtHours) {
    if (rollingDebtHours <= 1.0) {
      return const SleepDebtAssessment(
        level: SleepDebtLevel.optimal,
        title: 'OPTIMAL COGNITIVE CADENCE',
        advice: 'Minimal sleep debt. Peak executive function and motor control.',
        colorHex: 0xFF10B981, // Emerald
      );
    } else if (rollingDebtHours <= 4.0) {
      return const SleepDebtAssessment(
        level: SleepDebtLevel.moderate,
        title: 'MODERATE SLEEP DEBT',
        advice:
            'Mild cognitive slowdown. Aim for 30m earlier bedtime or a 20m afternoon power nap.',
        colorHex: 0xFFF59E0B, // Amber
      );
    } else {
      return const SleepDebtAssessment(
        level: SleepDebtLevel.critical,
        title: 'HIGH RECOVERY DEFICIT',
        advice:
            'Significant executive fatigue. Prioritize an 8.5h recovery sleep window tonight.',
        colorHex: 0xFFEF4444, // Red
      );
    }
  }

  // ── 6. Active Energy Ledger ───────────────────────────────────────────

  /// Calculates calories burned from an active workout exercise.
  /// Formula: (MET × 3.5 × weight in kg / 200) × duration in minutes
  /// If weightKg is not provided or 0, a default of 75kg is used.
  static int calculateActiveCalorieBurn({
    required double metValue,
    required double weightKg,
    required double durationMinutes,
  }) {
    final weight = (weightKg <= 0) ? 75.0 : weightKg;
    return ((metValue * 3.5 * weight / 200.0) * durationMinutes).round();
  }

  /// Calculates the Net Energy Balance for the day.
  /// Net Energy = Calories Consumed - (BMR + Active Energy Burned)
  /// Positive value means surplus (Gain), negative means deficit (Loss).
  static int calculateNetEnergyBalance({
    required int caloriesConsumed,
    required double bmr,
    required int activeEnergyBurned,
  }) {
    final totalOut = bmr.round() + activeEnergyBurned;
    return caloriesConsumed - totalOut;
  }
}

enum SleepDebtLevel { optimal, moderate, critical }

class SleepDebtAssessment {
  const SleepDebtAssessment({
    required this.level,
    required this.title,
    required this.advice,
    required this.colorHex,
  });

  final SleepDebtLevel level;
  final String title;
  final String advice;
  final int colorHex;
}
