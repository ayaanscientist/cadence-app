import 'package:equatable/equatable.dart';

/// A single historical entry recording what was completed vs. targeted.
class ExerciseHistoryEntry extends Equatable {

  factory ExerciseHistoryEntry.fromDb(dynamic row) {
    return ExerciseHistoryEntry(
      id: row.id as int?,
      exerciseTargetId: row.exerciseTargetId as String,
      date: row.date as String,
      repsCompleted: row.repsCompleted as int,
      targetWas: row.targetWas as int,
      createdAt: row.createdAt as DateTime?,
    );
  }
  const ExerciseHistoryEntry({
    this.id,
    required this.exerciseTargetId,
    required this.date,
    required this.repsCompleted,
    required this.targetWas,
    this.createdAt,
  });

  /// Auto-increment DB key (null before insertion).
  final int? id;

  /// FK → exercise_targets.id
  final String exerciseTargetId;

  /// Calendar date string (yyyy-MM-dd).
  final String date;

  /// Reps the user actually completed.
  final int repsCompleted;

  /// Snapshot of what the target was on this day.
  final int targetWas;

  final DateTime? createdAt;

  /// Whether the user met or exceeded the target.
  bool get hitTarget => repsCompleted >= targetWas;

  @override
  List<Object?> get props =>
      [id, exerciseTargetId, date, repsCompleted, targetWas];

  @override
  String toString() =>
      'ExerciseHistoryEntry($date: $repsCompleted/$targetWas)';
}
