import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'energy_dao.g.dart';

/// Data access object for [DailyEnergyLogs] and [MealEntries].
@DriftAccessor(tables: [DailyEnergyLogs, MealEntries])
class EnergyDao extends DatabaseAccessor<AppDatabase> with _$EnergyDaoMixin {
  EnergyDao(super.db);

  // ── Daily Energy Logs ───────────────────────────────────────────────────

  Future<DailyEnergyLogEntry?> getLogByDate(String date) =>
      (select(dailyEnergyLogs)..where((e) => e.date.equals(date)))
          .getSingleOrNull();

  Stream<DailyEnergyLogEntry?> watchLogByDate(String date) =>
      (select(dailyEnergyLogs)..where((e) => e.date.equals(date)))
          .watchSingleOrNull();

  Future<int> insertLog(DailyEnergyLogsCompanion entry) =>
      into(dailyEnergyLogs).insert(entry);

  Future<void> upsertLog(DailyEnergyLogsCompanion entry) =>
      into(dailyEnergyLogs).insertOnConflictUpdate(entry);

  Future<bool> updateLog(DailyEnergyLogEntry entry) =>
      update(dailyEnergyLogs).replace(entry);

  /// Recalculates consumed totals by summing all meal entries for the day.
  Future<void> recalculateTotals(String energyLogId) async {
    final meals = await getMealsForLog(energyLogId);
    final totalCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final totalProtein = meals.fold<int>(0, (sum, m) => sum + m.protein);
    final totalCarbs = meals.fold<int>(0, (sum, m) => sum + m.carbs);
    final totalFat = meals.fold<int>(0, (sum, m) => sum + m.fat);

    await (update(dailyEnergyLogs)
          ..where((e) => e.id.equals(energyLogId)))
        .write(
      DailyEnergyLogsCompanion(
        caloriesConsumed: Value(totalCalories),
        proteinConsumedGrams: Value(totalProtein),
        carbsGrams: Value(totalCarbs),
        fatGrams: Value(totalFat),
      ),
    );
  }

  // ── Meal Entries ────────────────────────────────────────────────────────

  Future<List<MealEntryRow>> getMealsForLog(String energyLogId) =>
      (select(mealEntries)
            ..where((m) => m.energyLogId.equals(energyLogId))
            ..orderBy([(m) => OrderingTerm.asc(m.time)]))
          .get();

  Stream<List<MealEntryRow>> watchMealsForLog(String energyLogId) =>
      (select(mealEntries)
            ..where((m) => m.energyLogId.equals(energyLogId))
            ..orderBy([(m) => OrderingTerm.asc(m.time)]))
          .watch();

  Future<int> insertMeal(MealEntriesCompanion entry) =>
      into(mealEntries).insert(entry);

  Future<int> deleteMeal(int id) =>
      (delete(mealEntries)..where((m) => m.id.equals(id))).go();
}
