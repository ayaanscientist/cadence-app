import 'package:equatable/equatable.dart';

/// Domain entity for daily nutrition tracking.
class NutritionLog extends Equatable {

  factory NutritionLog.fromDb(dynamic row, [List<MealEntry> meals = const []]) {
    return NutritionLog(
      id: row.id as String,
      date: row.date as String,
      calorieTarget: row.calorieTarget as int,
      caloriesConsumed: row.caloriesConsumed as int,
      proteinTargetGrams: row.proteinTargetGrams as int,
      proteinConsumedGrams: row.proteinConsumedGrams as int,
      carbsGrams: row.carbsGrams as int,
      fatGrams: row.fatGrams as int,
      meals: meals,
    );
  }
  const NutritionLog({
    required this.id,
    required this.date,
    this.calorieTarget = 2400,
    this.caloriesConsumed = 0,
    this.proteinTargetGrams = 160,
    this.proteinConsumedGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.meals = const [],
  });

  final String id;
  final String date;

  final int calorieTarget;
  final int caloriesConsumed;
  final int proteinTargetGrams;
  final int proteinConsumedGrams;
  final int carbsGrams;
  final int fatGrams;

  /// Child meal entries for this day.
  final List<MealEntry> meals;

  // ── Computed ─────────────────────────────────────────────────────────

  int get caloriesRemaining => calorieTarget - caloriesConsumed;
  int get proteinRemaining => proteinTargetGrams - proteinConsumedGrams;

  double get calorieProgress =>
      calorieTarget > 0 ? caloriesConsumed / calorieTarget : 0.0;

  double get proteinProgress =>
      proteinTargetGrams > 0 ? proteinConsumedGrams / proteinTargetGrams : 0.0;

  @override
  List<Object?> get props => [
        id,
        date,
        calorieTarget,
        caloriesConsumed,
        proteinTargetGrams,
        proteinConsumedGrams,
        carbsGrams,
        fatGrams,
        meals,
      ];
}

/// A single meal / food entry within a day.
class MealEntry extends Equatable {

  factory MealEntry.fromDb(dynamic row) {
    return MealEntry(
      id: row.id as int?,
      energyLogId: row.energyLogId as String,
      time: row.time as String,
      rawText: row.rawText as String,
      parsedByGemini: row.parsedByGemini as bool,
      calories: row.calories as int,
      protein: row.protein as int,
      carbs: row.carbs as int,
      fat: row.fat as int,
    );
  }
  const MealEntry({
    this.id,
    required this.energyLogId,
    required this.time,
    required this.rawText,
    this.parsedByGemini = false,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final int? id;
  final String energyLogId;

  /// Time of the meal (HH:mm).
  final String time;

  /// Raw user input, e.g. "4 whole eggs, 2 slices oats bread".
  final String rawText;

  /// Whether Gemini AI was used to parse this entry.
  final bool parsedByGemini;

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  @override
  List<Object?> get props =>
      [id, energyLogId, time, rawText, parsedByGemini, calories, protein, carbs, fat];

  @override
  String toString() => 'MealEntry($time: "$rawText", ${calories}kcal)';
}
