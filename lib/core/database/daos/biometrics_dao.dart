import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';
import 'package:cadence/features/physical/logic/biometric_calculator.dart';

part 'biometrics_dao.g.dart';

/// Data Access Object for User Biometrics and Daily Metabolic/Sleep Logs.
@DriftAccessor(tables: [UserBiometrics, DailyBiometricLogs])
class BiometricsDao extends DatabaseAccessor<AppDatabase> with _$BiometricsDaoMixin {
  BiometricsDao(super.db);

  static const _uuid = Uuid();
  static const String defaultProfileId = 'primary_user';

  // ── User Biometrics Profile ───────────────────────────────────────────

  /// Fetches the user's metabolic profile.
  Future<UserBiometricEntry?> getUserBiometrics({String id = defaultProfileId}) {
    return (select(userBiometrics)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Reactively watches the user's metabolic profile.
  Stream<UserBiometricEntry?> watchUserBiometrics({String id = defaultProfileId}) {
    return (select(userBiometrics)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Calculates and persists/updates the user's complete metabolic baseline.
  Future<void> upsertUserBiometrics({
    String id = defaultProfileId,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required double baselineSleepNeedHours,
    required String activityLevel,
    required String goal,
  }) async {
    // 1. Calculate derived metabolic metrics
    final bmr = BiometricCalculator.calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final tdee = BiometricCalculator.calculateTdee(
      bmr: bmr,
      activityLevel: activityLevel,
    );

    final targetCalories = BiometricCalculator.calculateTargetCalories(
      tdee: tdee,
      goal: goal,
    );

    final targetProteinGrams = BiometricCalculator.calculateProteinTarget(
      weightKg: weightKg,
    );

    // 2. Insert or update in SQLite
    await into(userBiometrics).insertOnConflictUpdate(
      UserBiometricsCompanion.insert(
        id: id,
        age: age,
        gender: Value(gender),
        heightCm: heightCm,
        weightKg: weightKg,
        targetWeightKg: targetWeightKg,
        baselineSleepNeedHours: Value(baselineSleepNeedHours),
        activityLevel: Value(activityLevel),
        goal: Value(goal),
        calculatedBmr: Value(bmr),
        calculatedTdee: Value(tdee),
        targetCalories: Value(targetCalories),
        targetProteinGrams: Value(targetProteinGrams),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Daily Biometric & Sleep Logs ──────────────────────────────────────

  /// Records daily weigh-in, sleep hours, sleep debt, and morning energy score.
  Future<void> logDailyBiometrics({
    required String date,
    double? weightKg,
    required double actualSleepHours,
    required double targetSleepHours,
    int energyScore = 7,
    String? notes,
  }) async {
    // 1. Calculate single-day sleep debt
    final dailyDebt = BiometricCalculator.calculateDailySleepDebt(
      targetSleepHours: targetSleepHours,
      actualSleepHours: actualSleepHours,
    );

    // 2. Fetch past 6 days to compute 7-day rolling sleep debt
    final pastLogs = await (select(dailyBiometricLogs)
          ..where((t) => t.date.isSmallerThanValue(date))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(6))
        .get();

    final debtHistory = pastLogs.map((e) => e.sleepDebtHours).toList()
      ..add(dailyDebt);

    final rollingDebt = BiometricCalculator.calculateRollingSleepDebt(debtHistory);

    // 3. Upsert entry for today
    final existing = await (select(dailyBiometricLogs)
          ..where((t) => t.date.equals(date)))
        .getSingleOrNull();

    final entryId = existing?.id ?? _uuid.v4();

    await into(dailyBiometricLogs).insertOnConflictUpdate(
      DailyBiometricLogsCompanion.insert(
        id: entryId,
        date: date,
        weightKg: Value(weightKg),
        actualSleepHours: Value(actualSleepHours),
        targetSleepHours: Value(targetSleepHours),
        sleepDebtHours: Value(dailyDebt),
        rollingSleepDebtHours: Value(rollingDebt),
        energyScore: Value(energyScore),
        notes: Value(notes),
        loggedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get biometric log for a specific calendar date (yyyy-MM-dd).
  Future<DailyBiometricLogEntry?> getBiometricLogForDate(String date) {
    return (select(dailyBiometricLogs)..where((t) => t.date.equals(date)))
        .getSingleOrNull();
  }

  /// Reactively watch log for a date.
  Stream<DailyBiometricLogEntry?> watchBiometricLogForDate(String date) {
    return (select(dailyBiometricLogs)..where((t) => t.date.equals(date)))
        .watchSingleOrNull();
  }

  /// Fetches recent biometric logs (e.g. last 7 or 30 days).
  Future<List<DailyBiometricLogEntry>> getRecentLogs({int limit = 7}) {
    return (select(dailyBiometricLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }
}
