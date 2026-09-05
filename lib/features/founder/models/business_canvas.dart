import 'package:equatable/equatable.dart';

/// Validation lifecycle stages for a business idea.
enum CanvasStatus { brainstorming, validating, building, launched, archived }

/// Domain entity for a lean startup business idea canvas.
class BusinessCanvas extends Equatable {

  factory BusinessCanvas.fromDb(dynamic row) {
    return BusinessCanvas(
      id: row.id as String,
      ideaTitle: row.ideaTitle as String,
      problem: row.problem as String,
      targetCustomer: row.targetCustomer as String,
      solution: row.solution as String,
      monetization: row.monetization as String?,
      validationScore: row.validationScore as double,
      status: _parseStatus(row.status as String),
      createdAt: row.createdAt as DateTime?,
    );
  }
  const BusinessCanvas({
    required this.id,
    required this.ideaTitle,
    required this.problem,
    required this.targetCustomer,
    required this.solution,
    this.monetization,
    this.validationScore = 0.0,
    this.status = CanvasStatus.brainstorming,
    this.createdAt,
  });

  final String id;
  final String ideaTitle;
  final String problem;
  final String targetCustomer;
  final String solution;
  final String? monetization;

  /// Subjective validation score (0.0 – 10.0).
  final double validationScore;

  final CanvasStatus status;
  final DateTime? createdAt;

  // ── Computed ─────────────────────────────────────────────────────────

  /// Quick check: is the idea actively being validated or built?
  bool get isActive =>
      status == CanvasStatus.validating || status == CanvasStatus.building;

  /// Validation score as a percentage (0–100).
  double get validationPercent => (validationScore / 10.0) * 100;

  // ── Serialisation ───────────────────────────────────────────────────

  static CanvasStatus _parseStatus(String value) {
    return CanvasStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => CanvasStatus.brainstorming,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ideaTitle,
        problem,
        targetCustomer,
        solution,
        monetization,
        validationScore,
        status,
        createdAt,
      ];

  @override
  String toString() =>
      'BusinessCanvas("$ideaTitle", score: $validationScore, status: $status)';
}
