import 'package:equatable/equatable.dart';

/// Domain entity combining meditation session and sleep data for a single day.
class MentalLog extends Equatable {

  factory MentalLog.fromDb(dynamic row) {
    return MentalLog(
      id: row.id as String,
      date: row.date as String,
      meditationScheduledTime: row.meditationScheduledTime as String?,
      meditationDurationTargetSeconds:
          row.meditationDurationTargetSeconds as int,
      meditationDurationActualSeconds:
          row.meditationDurationActualSeconds as int?,
      meditationCompleted: row.meditationCompleted as bool,
      ambientPreset: row.ambientPreset as String?,
      windDownAlarm: row.windDownAlarm as String?,
      targetBedtime: row.targetBedtime as String?,
      actualBedtime: row.actualBedtime as String?,
      wakeAlarm: row.wakeAlarm as String?,
      actualWakeTime: row.actualWakeTime as String?,
      subjectiveEnergyScore: row.subjectiveEnergyScore as int?,
    );
  }
  const MentalLog({
    required this.id,
    required this.date,
    this.meditationScheduledTime,
    this.meditationDurationTargetSeconds = 900,
    this.meditationDurationActualSeconds,
    this.meditationCompleted = false,
    this.ambientPreset,
    this.windDownAlarm,
    this.targetBedtime,
    this.actualBedtime,
    this.wakeAlarm,
    this.actualWakeTime,
    this.subjectiveEnergyScore,
  });

  final String id;

  /// Calendar date (yyyy-MM-dd).
  final String date;

  // ── Meditation ──────────────────────────────────────────────────────

  /// Scheduled exact alarm time for meditation (HH:mm).
  final String? meditationScheduledTime;

  /// Target duration in seconds (default 900 = 15 min).
  final int meditationDurationTargetSeconds;

  /// Actual elapsed seconds (null if not yet completed).
  final int? meditationDurationActualSeconds;

  final bool meditationCompleted;

  /// Audio preset key, e.g. "singing_bowl_chime".
  final String? ambientPreset;

  // ── Sleep ───────────────────────────────────────────────────────────

  /// Wind-down alarm (HH:mm) — triggers DND / dimming.
  final String? windDownAlarm;

  /// Target bedtime (HH:mm).
  final String? targetBedtime;

  /// Actual bedtime logged by user (HH:mm).
  final String? actualBedtime;

  /// Wake-up alarm (HH:mm).
  final String? wakeAlarm;

  /// Actual wake time (HH:mm).
  final String? actualWakeTime;

  /// Subjective morning energy (1–5 scale).
  final int? subjectiveEnergyScore;

  // ── Computed ─────────────────────────────────────────────────────────

  /// Meditation completion percentage (0.0 – 1.0+).
  double get meditationProgress {
    if (meditationDurationActualSeconds == null ||
        meditationDurationTargetSeconds == 0) {
      return 0.0;
    }
    return meditationDurationActualSeconds! / meditationDurationTargetSeconds;
  }

  /// Rough sleep duration in minutes (null if data is incomplete).
  /// This is a simplified calculation; a full implementation would
  /// parse HH:mm strings and handle midnight crossings.
  int? get estimatedSleepMinutes {
    if (actualBedtime == null || actualWakeTime == null) return null;
    final bed = _parseHhmm(actualBedtime!);
    final wake = _parseHhmm(actualWakeTime!);
    if (bed == null || wake == null) return null;
    var diff = wake - bed;
    if (diff < 0) diff += 24 * 60; // crossed midnight
    return diff;
  }

  static int? _parseHhmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  @override
  List<Object?> get props => [
        id,
        date,
        meditationScheduledTime,
        meditationDurationTargetSeconds,
        meditationDurationActualSeconds,
        meditationCompleted,
        ambientPreset,
        windDownAlarm,
        targetBedtime,
        actualBedtime,
        wakeAlarm,
        actualWakeTime,
        subjectiveEnergyScore,
      ];

  @override
  String toString() =>
      'MentalLog($date, meditation: $meditationCompleted, energy: $subjectiveEnergyScore)';
}
