import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'bad_habits_dao.g.dart';

/// Data Access Object for Inverted Atomic Habits (Bad Habits) and Relapse Tracking.
@DriftAccessor(tables: [BadHabits, BadHabitRelapses])
class BadHabitsDao extends DatabaseAccessor<AppDatabase> with _$BadHabitsDaoMixin {
  BadHabitsDao(super.db);

  static const _uuid = Uuid();

  /// Watch all currently active bad habits.
  Stream<List<BadHabitEntry>> watchActiveBadHabits() {
    return (select(badHabits)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get all bad habits.
  Future<List<BadHabitEntry>> getAllBadHabits() {
    return select(badHabits).get();
  }

  /// Get a single bad habit by its UUID.
  Future<BadHabitEntry?> getBadHabitById(String id) {
    return (select(badHabits)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Create a new bad habit tracking entry.
  Future<int> insertBadHabit({
    required String title,
    required double costPerDay,
    String currency = 'USD',
    DateTime? quitDate,
  }) {
    final startQuit = quitDate ?? DateTime.now();
    return into(badHabits).insert(
      BadHabitsCompanion.insert(
        id: _uuid.v4(),
        title: title,
        costPerDay: Value(costPerDay),
        currency: Value(currency),
        quitDate: startQuit,
        cleanStreakDays: const Value(0),
        cravingsResisted: const Value(0),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Records a successfully resisted craving (Urge Surfed via SOS Delay Timer).
  Future<void> recordCravingResisted(String habitId) async {
    final habit = await getBadHabitById(habitId);
    if (habit != null) {
      await (update(badHabits)..where((t) => t.id.equals(habitId))).write(
        BadHabitsCompanion(
          cravingsResisted: Value(habit.cravingsResisted + 1),
        ),
      );
    }
  }

  /// Records a relapse: audits the trigger, logs to `bad_habit_relapses`,
  /// and resets the habit's clean streak and quitDate to now.
  Future<void> recordRelapse({
    required String badHabitId,
    required String trigger,
    String? notes,
    double? moneyLost,
  }) async {
    final habit = await getBadHabitById(badHabitId);
    if (habit == null) return;

    final now = DateTime.now();
    final cleanDaysPrior = now.difference(habit.quitDate).inDays;

    // 1. Insert audit log of the relapse
    await into(badHabitRelapses).insert(
      BadHabitRelapsesCompanion.insert(
        id: _uuid.v4(),
        badHabitId: badHabitId,
        relapseTimestamp: now,
        cleanDaysPrior: cleanDaysPrior < 0 ? 0 : cleanDaysPrior,
        trigger: trigger,
        notes: Value(notes),
        moneyLost: Value(moneyLost),
      ),
    );

    // 2. Reset clean streak clock
    await (update(badHabits)..where((t) => t.id.equals(badHabitId))).write(
      BadHabitsCompanion(
        quitDate: Value(now),
        cleanStreakDays: const Value(0),
      ),
    );
  }

  /// Fetch all historical relapses for a specific bad habit.
  Future<List<BadHabitRelapseEntry>> getRelapsesForHabit(String badHabitId) {
    return (select(badHabitRelapses)
          ..where((t) => t.badHabitId.equals(badHabitId))
          ..orderBy([(t) => OrderingTerm.desc(t.relapseTimestamp)]))
        .get();
  }

  /// Soft deletes or deactivates a bad habit.
  Future<int> deactivateBadHabit(String id) {
    return (update(badHabits)..where((t) => t.id.equals(id))).write(
      const BadHabitsCompanion(isActive: Value(false)),
    );
  }
}
