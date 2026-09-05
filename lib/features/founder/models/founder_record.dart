import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Domain entity for the daily founder log — tracks "One Big Thing",
/// deep-work focus, and evening retrospective.
class FounderRecord extends Equatable {

  // ── Serialisation ───────────────────────────────────────────────────

  factory FounderRecord.fromDb(dynamic row) {
    List<String> parsedTopThree = const [];
    final raw = row.tomorrowTopThree as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        parsedTopThree = List<String>.from(jsonDecode(raw) as List);
      } catch (_) {
        parsedTopThree = [];
      }
    }

    return FounderRecord(
      id: row.id as String,
      date: row.date as String,
      oneBigThing: row.oneBigThing as String,
      oneBigThingCompleted: row.oneBigThingCompleted as bool,
      focusDurationMinutes: row.focusDurationMinutes as int,
      needleMoved: row.needleMoved as String?,
      frictionPoint: row.frictionPoint as String?,
      tomorrowTopThree: parsedTopThree,
    );
  }
  const FounderRecord({
    required this.id,
    required this.date,
    required this.oneBigThing,
    this.oneBigThingCompleted = false,
    this.focusDurationMinutes = 0,
    this.needleMoved,
    this.frictionPoint,
    this.tomorrowTopThree = const [],
  });

  final String id;

  /// Calendar date (yyyy-MM-dd).
  final String date;

  /// The single highest-leverage task for today.
  final String oneBigThing;

  final bool oneBigThingCompleted;

  /// Minutes spent in deep-work focus blocks.
  final int focusDurationMinutes;

  /// Evening retro: what actually moved the needle today.
  final String? needleMoved;

  /// Evening retro: what caused friction or wasted time.
  final String? frictionPoint;

  /// Up to 3 priorities for tomorrow.
  final List<String> tomorrowTopThree;

  // ── Computed ─────────────────────────────────────────────────────────

  /// Hours and minutes of deep work, formatted as "1h 50m".
  String get focusDurationFormatted {
    final h = focusDurationMinutes ~/ 60;
    final m = focusDurationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Whether the evening retrospective has been filled in.
  bool get hasRetrospective => needleMoved != null || frictionPoint != null;

  /// Encodes [tomorrowTopThree] to JSON for database storage.
  String get tomorrowTopThreeJson => jsonEncode(tomorrowTopThree);

  @override
  List<Object?> get props => [
        id,
        date,
        oneBigThing,
        oneBigThingCompleted,
        focusDurationMinutes,
        needleMoved,
        frictionPoint,
        tomorrowTopThree,
      ];

  @override
  String toString() =>
      'FounderRecord($date, OBT: "$oneBigThing", completed: $oneBigThingCompleted)';
}
