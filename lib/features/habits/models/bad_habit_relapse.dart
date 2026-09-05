import 'package:equatable/equatable.dart';

/// Domain entity for an audited relapse event.
class BadHabitRelapse extends Equatable {

  factory BadHabitRelapse.fromDb(dynamic row) {
    return BadHabitRelapse(
      id: row.id as String,
      badHabitId: row.badHabitId as String,
      relapseTimestamp: row.relapseTimestamp as DateTime,
      cleanDaysPrior: row.cleanDaysPrior as int,
      trigger: row.trigger as String,
      notes: row.notes as String?,
      moneyLost: row.moneyLost != null ? (row.moneyLost as num).toDouble() : null,
    );
  }
  const BadHabitRelapse({
    required this.id,
    required this.badHabitId,
    required this.relapseTimestamp,
    required this.cleanDaysPrior,
    required this.trigger,
    this.notes,
    this.moneyLost,
  });

  final String id;
  final String badHabitId;
  final DateTime relapseTimestamp;
  final int cleanDaysPrior;
  final String trigger;
  final String? notes;
  final double? moneyLost;

  @override
  List<Object?> get props => [
        id,
        badHabitId,
        relapseTimestamp,
        cleanDaysPrior,
        trigger,
        notes,
        moneyLost,
      ];
}
