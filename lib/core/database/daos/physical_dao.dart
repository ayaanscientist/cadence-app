import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'physical_dao.g.dart';

/// Data access object for [ExerciseTargets] and [ExerciseHistory].
///
/// Provides queries for the progressive overload engine and
/// historical rep tracking.
@DriftAccessor(tables: [ExerciseTargets, ExerciseHistory])
class PhysicalDao extends DatabaseAccessor<AppDatabase>
    with _$PhysicalDaoMixin {
  PhysicalDao(super.db);

  // ── Exercise Targets ────────────────────────────────────────────────────

  Future<List<ExerciseTargetEntry>> getAllTargets() =>
      select(exerciseTargets).get();

  Stream<List<ExerciseTargetEntry>> watchAllTargets() =>
      select(exerciseTargets).watch();

  Future<ExerciseTargetEntry?> getTargetById(String id) =>
      (select(exerciseTargets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTarget(ExerciseTargetsCompanion entry) =>
      into(exerciseTargets).insert(entry);

  Future<bool> updateTarget(ExerciseTargetEntry entry) =>
      update(exerciseTargets).replace(entry);

  /// Updates only the rep-related columns after a progression calculation.
  Future<void> updateProgression({
    required String id,
    required double newCurrentReps,
    required double newAccumulator,
  }) async {
    await (update(exerciseTargets)..where((t) => t.id.equals(id))).write(
      ExerciseTargetsCompanion(
        currentReps: Value(newCurrentReps),
        fractionalAccumulator: Value(newAccumulator),
      ),
    );
  }

  Future<int> deleteTarget(String id) =>
      (delete(exerciseTargets)..where((t) => t.id.equals(id))).go();

  // ── Exercise History ────────────────────────────────────────────────────

  /// Returns the full history for a given exercise, newest first.
  Future<List<ExerciseHistoryEntry>> getHistory(String exerciseTargetId) =>
      (select(exerciseHistory)
            ..where((h) => h.exerciseTargetId.equals(exerciseTargetId))
            ..orderBy([(h) => OrderingTerm.desc(h.date)]))
          .get();

  Stream<List<ExerciseHistoryEntry>> watchHistory(String exerciseTargetId) =>
      (select(exerciseHistory)
            ..where((h) => h.exerciseTargetId.equals(exerciseTargetId))
            ..orderBy([(h) => OrderingTerm.desc(h.date)]))
          .watch();

  /// Logs a completed day's reps and the target that was set.
  Future<int> logCompletion(ExerciseHistoryCompanion entry) =>
      into(exerciseHistory).insert(entry);
}
