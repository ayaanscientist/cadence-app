import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'habits_dao.g.dart';

/// Data access object for the [Habits] table.
///
/// Encapsulates all CRUD operations and the Never-Miss-Twice
/// state machine transitions for habits.
@DriftAccessor(tables: [Habits])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Returns all habits ordered by creation date (newest first).
  Future<List<HabitEntry>> getAllHabits() =>
      (select(habits)..orderBy([(h) => OrderingTerm.desc(h.createdAt)])).get();

  /// Watches all habits reactively (for Riverpod stream providers).
  Stream<List<HabitEntry>> watchAllHabits() =>
      (select(habits)..orderBy([(h) => OrderingTerm.desc(h.createdAt)])).watch();

  /// Fetches a single habit by its UUID.
  Future<HabitEntry?> getHabitById(String id) =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  /// Returns habits chained to the given trigger (habit stacking lookup).
  Future<List<HabitEntry>> getStackedHabits(String triggerHabitId) =>
      (select(habits)..where((h) => h.triggerHabitId.equals(triggerHabitId)))
          .get();

  /// Returns all habits currently in the AT_RISK state.
  Future<List<HabitEntry>> getAtRiskHabits() =>
      (select(habits)..where((h) => h.statusState.equals('atRisk'))).get();

  // ── Mutations ───────────────────────────────────────────────────────────

  /// Inserts a new habit.
  Future<int> insertHabit(HabitsCompanion entry) => into(habits).insert(entry);

  /// Updates an existing habit row.
  Future<bool> updateHabit(HabitEntry entry) => update(habits).replace(entry);

  /// Deletes a habit by its UUID.
  Future<int> deleteHabit(String id) =>
      (delete(habits)..where((h) => h.id.equals(id))).go();

  // ── Never-Miss-Twice State Machine ──────────────────────────────────────

  /// Marks a habit as completed today. Resets AT_RISK → ACTIVE,
  /// increments streak, clears the never-miss-twice flag.
  Future<void> markCompleted(String id) async {
    final habit = await getHabitById(id);
    if (habit == null) return;

    await (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        currentStreak: Value(habit.currentStreak + 1),
        statusState: const Value('active'),
        neverMissTwiceFlag: const Value(false),
        lastCompletedTimestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Evaluates a missed day. Called by the daily 23:59 daemon.
  ///
  /// - ACTIVE → AT_RISK (sets never_miss_twice_flag)
  /// - AT_RISK → BROKEN (resets streak to 0)
  Future<void> evaluateMissedDay(String id) async {
    final habit = await getHabitById(id);
    if (habit == null) return;

    final currentStatus = habit.statusState;

    if (currentStatus == 'active') {
      await (update(habits)..where((h) => h.id.equals(id))).write(
        const HabitsCompanion(
          statusState: Value('atRisk'),
          neverMissTwiceFlag: Value(true),
        ),
      );
    } else if (currentStatus == 'atRisk') {
      await (update(habits)..where((h) => h.id.equals(id))).write(
        const HabitsCompanion(
          statusState: Value('broken'),
          neverMissTwiceFlag: Value(false),
          currentStreak: Value(0),
        ),
      );
    }
  }
}
