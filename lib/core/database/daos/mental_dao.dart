import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'mental_dao.g.dart';

/// Data access object for [MentalLogs] (meditation + sleep).
@DriftAccessor(tables: [MentalLogs])
class MentalDao extends DatabaseAccessor<AppDatabase> with _$MentalDaoMixin {
  MentalDao(super.db);

  /// Returns the mental log for a specific date (yyyy-MM-dd).
  Future<MentalLogEntry?> getLogByDate(String date) =>
      (select(mentalLogs)..where((m) => m.date.equals(date)))
          .getSingleOrNull();

  Stream<MentalLogEntry?> watchLogByDate(String date) =>
      (select(mentalLogs)..where((m) => m.date.equals(date)))
          .watchSingleOrNull();

  /// Returns all logs, newest first.
  Future<List<MentalLogEntry>> getAllLogs() =>
      (select(mentalLogs)..orderBy([(m) => OrderingTerm.desc(m.date)])).get();

  Future<int> insertLog(MentalLogsCompanion entry) =>
      into(mentalLogs).insert(entry);

  Future<bool> updateLog(MentalLogEntry entry) =>
      update(mentalLogs).replace(entry);

  /// Upserts: insert if no row exists for [date], otherwise update.
  Future<void> upsertLog(MentalLogsCompanion entry) =>
      into(mentalLogs).insertOnConflictUpdate(entry);

  /// Marks today's meditation as completed with the actual duration.
  Future<void> completeMeditation({
    required String id,
    required int actualSeconds,
  }) async {
    await (update(mentalLogs)..where((m) => m.id.equals(id))).write(
      MentalLogsCompanion(
        meditationCompleted: const Value(true),
        meditationDurationActualSeconds: Value(actualSeconds),
      ),
    );
  }

  /// Logs sleep data for a given day.
  Future<void> logSleep({
    required String id,
    required String actualBedtime,
    required String actualWakeTime,
    required int energyScore,
  }) async {
    await (update(mentalLogs)..where((m) => m.id.equals(id))).write(
      MentalLogsCompanion(
        actualBedtime: Value(actualBedtime),
        actualWakeTime: Value(actualWakeTime),
        subjectiveEnergyScore: Value(energyScore),
      ),
    );
  }
}
