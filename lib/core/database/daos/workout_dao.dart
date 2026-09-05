import 'package:drift/drift.dart';
import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [
  Exercises,
  WorkoutSessions,
  CompletedExerciseLogs,
  ExerciseStats,
  DailyEnergyLogs
])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  /// Fetches all predefined exercises.
  Future<List<ExerciseEntry>> getAllExercises() => select(exercises).get();

  /// Creates a new workout session and returns its ID.
  Future<String> startSession() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await into(workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        id: sessionId,
        startTimestamp: DateTime.now(),
        status: const Value('IN_PROGRESS'),
      ),
    );
    return sessionId;
  }

  /// Logs a completed exercise within a session and updates lifetime stats.
  Future<void> logCompletedExercise({
    required String sessionId,
    required String exerciseId,
    required int repsDone,
    required int durationSec,
    required int caloriesBurnedKcal,
    required String todayDateString,
  }) async {
    return transaction(() async {
      // 1. Insert log
      await into(completedExerciseLogs).insert(
        CompletedExerciseLogsCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: sessionId,
          exerciseId: exerciseId,
          repsDone: Value(repsDone),
          durationSec: Value(durationSec),
          caloriesBurnedKcal: Value(caloriesBurnedKcal),
        ),
      );

      // 2. Update session total calories
      final sessionQuery = select(workoutSessions)..where((s) => s.id.equals(sessionId));
      final session = await sessionQuery.getSingleOrNull();
      if (session != null) {
        final newTotal = session.totalEnergyBurnedKcal + caloriesBurnedKcal;
        await update(workoutSessions).replace(session.copyWith(totalEnergyBurnedKcal: newTotal));
      }

      // 3. Upsert ExerciseStats
      final statQuery = select(exerciseStats)..where((s) => s.exerciseId.equals(exerciseId));
      final currentStat = await statQuery.getSingleOrNull();
      
      if (currentStat != null) {
        await update(exerciseStats).replace(
          currentStat.copyWith(
            lifetimeCompletionsCount: currentStat.lifetimeCompletionsCount + 1,
            allTimeRepsCount: currentStat.allTimeRepsCount + repsDone,
            allTimeEnergyBurned: currentStat.allTimeEnergyBurned + caloriesBurnedKcal,
          ),
        );
      } else {
        await into(exerciseStats).insert(
          ExerciseStatsCompanion.insert(
            exerciseId: exerciseId,
            lifetimeCompletionsCount: const Value(1),
            allTimeRepsCount: Value(repsDone),
            allTimeEnergyBurned: Value(caloriesBurnedKcal),
          ),
        );
      }

      // 4. Update DailyEnergyLogs active burn
      final dailyLogQuery = select(dailyEnergyLogs)..where((l) => l.date.equals(todayDateString));
      final currentDailyLog = await dailyLogQuery.getSingleOrNull();
      if (currentDailyLog != null) {
        await update(dailyEnergyLogs).replace(
          currentDailyLog.copyWith(
            activeEnergyBurned: currentDailyLog.activeEnergyBurned + caloriesBurnedKcal,
          ),
        );
      }
    });
  }

  /// Ends the session.
  Future<void> endSession(String sessionId) async {
    final query = select(workoutSessions)..where((s) => s.id.equals(sessionId));
    final session = await query.getSingleOrNull();
    if (session != null) {
      await update(workoutSessions).replace(
        session.copyWith(
          endTimestamp: Value(DateTime.now()),
          status: 'COMPLETED',
        ),
      );
    }
  }
}
