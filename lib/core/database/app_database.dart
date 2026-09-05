import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:cadence/core/constants/app_constants.dart';
import 'package:cadence/core/database/tables.dart';
import 'package:cadence/core/database/daos/habits_dao.dart';
import 'package:cadence/core/database/daos/physical_dao.dart';
import 'package:cadence/core/database/daos/mental_dao.dart';
import 'package:cadence/core/database/daos/energy_dao.dart';
import 'package:cadence/core/database/daos/founder_dao.dart';
import 'package:cadence/core/database/daos/bad_habits_dao.dart';
import 'package:cadence/core/database/daos/settings_dao.dart';
import 'package:cadence/core/database/daos/workout_dao.dart';
import 'package:cadence/core/database/daos/gamification_dao.dart';
import 'package:cadence/core/database/daos/biometrics_dao.dart';
import 'package:cadence/core/database/daos/alter_ego_dao.dart';

part 'app_database.g.dart';

/// The single Drift database instance for Cadence.
///
/// All tables are registered here. Code generation via `build_runner`
/// produces `app_database.g.dart` with query implementations.
@DriftDatabase(
  tables: [
    Habits,
    ExerciseTargets,
    ExerciseHistory,
    MentalLogs,
    DailyEnergyLogs,
    MealEntries,
    FounderRecords,
    BusinessCanvases,
    BookNotes,
    BadHabits,
    BadHabitRelapses,
    AppSettings,
    UserBiometrics,
    DailyBiometricLogs,
    AlterEgoProfiles,
    Exercises,
    WorkoutSessions,
    CompletedExerciseLogs,
    ExerciseStats,
    GamificationProfiles,
  ],
  daos: [
    HabitsDao,
    PhysicalDao,
    MentalDao,
    EnergyDao,
    FounderDao,
    BadHabitsDao,
    SettingsDao,
    BiometricsDao,
    AlterEgoDao,
    WorkoutDao,
    GamificationDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor accepting an in-memory or custom [QueryExecutor]
  /// for testing and DI scenarios.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => AppConstants.databaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations will go here.
          // Example:
          // if (from < 2) {
          //   await m.addColumn(habits, habits.someNewColumn);
          // }
        },
      );
}

/// Opens a native SQLite connection at the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseFileName));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}
