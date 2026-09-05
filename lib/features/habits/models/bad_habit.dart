import 'package:equatable/equatable.dart';

/// Domain entity representing a bad habit being overcome (Inverted Atomic Habit).
class BadHabit extends Equatable {

  factory BadHabit.fromDb(dynamic row) {
    return BadHabit(
      id: row.id as String,
      title: row.title as String,
      costPerDay: (row.costPerDay as num).toDouble(),
      currency: row.currency as String,
      quitDate: row.quitDate as DateTime,
      cleanStreakDays: row.cleanStreakDays as int,
      cravingsResisted: row.cravingsResisted as int,
      isActive: row.isActive as bool,
      createdAt: row.createdAt as DateTime,
    );
  }
  const BadHabit({
    required this.id,
    required this.title,
    this.costPerDay = 0.0,
    this.currency = 'USD',
    required this.quitDate,
    this.cleanStreakDays = 0,
    this.cravingsResisted = 0,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double costPerDay;
  final String currency;
  final DateTime quitDate;
  final int cleanStreakDays;
  final int cravingsResisted;
  final bool isActive;
  final DateTime createdAt;

  /// Dynamically computes elapsed clean days from the quit date to now.
  int get calculatedCleanDays {
    final diff = DateTime.now().difference(quitDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Total money saved since quit date based on clean days and daily cost.
  double get totalMoneySaved => calculatedCleanDays * costPerDay;

  /// Formatted money saved string, e.g. "$420.00".
  String get formattedMoneySaved {
    final symbol = currency == 'USD'
        ? '\$'
        : (currency == 'EUR' ? '€' : (currency == 'GBP' ? '£' : '$currency '));
    return '$symbol${totalMoneySaved.toStringAsFixed(2)}';
  }

  BadHabit copyWith({
    String? id,
    String? title,
    double? costPerDay,
    String? currency,
    DateTime? quitDate,
    int? cleanStreakDays,
    int? cravingsResisted,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BadHabit(
      id: id ?? this.id,
      title: title ?? this.title,
      costPerDay: costPerDay ?? this.costPerDay,
      currency: currency ?? this.currency,
      quitDate: quitDate ?? this.quitDate,
      cleanStreakDays: cleanStreakDays ?? this.cleanStreakDays,
      cravingsResisted: cravingsResisted ?? this.cravingsResisted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        costPerDay,
        currency,
        quitDate,
        cleanStreakDays,
        cravingsResisted,
        isActive,
        createdAt,
      ];
}
