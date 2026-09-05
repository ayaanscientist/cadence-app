import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cadence/core/database/tables.dart';
import 'package:cadence/features/founder/models/founder_record.dart';

/// State of the interactive Focus Countdown on the One Big Thing card.
class FocusCountdownState {
  const FocusCountdownState({
    this.totalSeconds = 45 * 60,
    this.remainingSeconds = 45 * 60,
    this.isRunning = false,
    this.isPaused = false,
    this.isCompleted = false,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;

  double get progress => totalSeconds > 0
      ? (totalSeconds - remainingSeconds) / totalSeconds
      : 0.0;

  String get formattedTimer {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  FocusCountdownState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isCompleted,
  }) {
    return FocusCountdownState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Represents the Next Habit in an atomic habit stacking chain.
class NextRoutineState {
  const NextRoutineState({
    required this.triggerHabitTitle,
    required this.actionHabitTitle,
    required this.stackFormula,
    required this.estimatedDurationMinutes,
    this.isCompleted = false,
  });

  final String triggerHabitTitle;
  final String actionHabitTitle;
  final String stackFormula;
  final int estimatedDurationMinutes;
  final bool isCompleted;

  NextRoutineState copyWith({
    String? triggerHabitTitle,
    String? actionHabitTitle,
    String? stackFormula,
    int? estimatedDurationMinutes,
    bool? isCompleted,
  }) {
    return NextRoutineState(
      triggerHabitTitle: triggerHabitTitle ?? this.triggerHabitTitle,
      actionHabitTitle: actionHabitTitle ?? this.actionHabitTitle,
      stackFormula: stackFormula ?? this.stackFormula,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Complete tactical state model for the AtomicOS Main Dashboard.
class DashboardState {
  const DashboardState({
    required this.formattedDate,
    required this.systemStatus,
    required this.streakDays,
    required this.streakStatus,
    required this.obtRecord,
    required this.focusState,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.caloriesConsumed,
    required this.calorieTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.exerciseName,
    required this.exerciseTargetReps,
    required this.exerciseCompletedReps,
    required this.exerciseIncrementRate,
    required this.nextRoutine,
  });

  final String formattedDate;
  final String systemStatus;
  final int streakDays;
  final HabitStatus streakStatus;
  final FounderRecord obtRecord;
  final FocusCountdownState focusState;
  final int habitsCompleted;
  final int habitsTotal;
  final int caloriesConsumed;
  final int calorieTarget;
  final int proteinConsumed;
  final int proteinTarget;
  final String exerciseName;
  final int exerciseTargetReps;
  final int exerciseCompletedReps;
  final String exerciseIncrementRate;
  final NextRoutineState nextRoutine;

  double get habitsProgress =>
      habitsTotal > 0 ? (habitsCompleted / habitsTotal).clamp(0.0, 1.0) : 0.0;

  double get calorieProgress =>
      calorieTarget > 0 ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.0) : 0.0;

  double get proteinProgress =>
      proteinTarget > 0 ? (proteinConsumed / proteinTarget).clamp(0.0, 1.0) : 0.0;

  double get exerciseProgress => exerciseTargetReps > 0
      ? (exerciseCompletedReps / exerciseTargetReps).clamp(0.0, 1.0)
      : 0.0;

  bool get isNeverMissTwiceAlert => streakStatus == HabitStatus.atRisk;

  DashboardState copyWith({
    String? formattedDate,
    String? systemStatus,
    int? streakDays,
    HabitStatus? streakStatus,
    FounderRecord? obtRecord,
    FocusCountdownState? focusState,
    int? habitsCompleted,
    int? habitsTotal,
    int? caloriesConsumed,
    int? calorieTarget,
    int? proteinConsumed,
    int? proteinTarget,
    String? exerciseName,
    int? exerciseTargetReps,
    int? exerciseCompletedReps,
    String? exerciseIncrementRate,
    NextRoutineState? nextRoutine,
  }) {
    return DashboardState(
      formattedDate: formattedDate ?? this.formattedDate,
      systemStatus: systemStatus ?? this.systemStatus,
      streakDays: streakDays ?? this.streakDays,
      streakStatus: streakStatus ?? this.streakStatus,
      obtRecord: obtRecord ?? this.obtRecord,
      focusState: focusState ?? this.focusState,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseTargetReps: exerciseTargetReps ?? this.exerciseTargetReps,
      exerciseCompletedReps:
          exerciseCompletedReps ?? this.exerciseCompletedReps,
      exerciseIncrementRate:
          exerciseIncrementRate ?? this.exerciseIncrementRate,
      nextRoutine: nextRoutine ?? this.nextRoutine,
    );
  }
}

/// State notifier managing real-time countdowns and dashboard stats.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(_initialState()) {
    _startClockRefresh();
  }

  Timer? _countdownTimer;
  Timer? _clockTimer;

  static DashboardState _initialState() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return DashboardState(
      formattedDate: dateStr,
      systemStatus: 'OFFLINE ENGINE ACTIVE • ACID READY',
      streakDays: 14,
      streakStatus: HabitStatus.active,
      obtRecord: FounderRecord(
        id: 'obt_today',
        date: DateFormat('yyyy-MM-dd').format(now),
        oneBigThing: 'Finalize AtomicOS Core Architecture & Phase 2 Services',
        oneBigThingCompleted: false,
        focusDurationMinutes: 45,
      ),
      focusState: const FocusCountdownState(
        totalSeconds: 45 * 60,
        remainingSeconds: 45 * 60,
      ),
      habitsCompleted: 4,
      habitsTotal: 5,
      caloriesConsumed: 1850,
      calorieTarget: 2400,
      proteinConsumed: 125,
      proteinTarget: 160,
      exerciseName: 'Pushups',
      exerciseTargetReps: 12,
      exerciseCompletedReps: 12,
      exerciseIncrementRate: '+1 rep / 1% compounding formula',
      nextRoutine: const NextRoutineState(
        triggerHabitTitle: 'Morning Meditation (10m)',
        actionHabitTitle: '20m Lean Startup Validation',
        stackFormula:
            'After I complete Morning Meditation, I will do 20m Business Planning & Canvas Review.',
        estimatedDurationMinutes: 20,
      ),
    );
  }

  void _startClockRefresh() {
    _clockTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();
      state = state.copyWith(formattedDate: dateStr);
    });
  }

  /// Starts or resumes the One Big Thing deep-work countdown.
  void launchDeepWorkCountdown({int minutes = 45}) {
    _countdownTimer?.cancel();

    final totalSec = minutes * 60;
    state = state.copyWith(
      focusState: FocusCountdownState(
        totalSeconds: totalSec,
        remainingSeconds: totalSec,
        isRunning: true,
        isPaused: false,
        isCompleted: false,
      ),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.focusState.remainingSeconds > 1) {
        state = state.copyWith(
          focusState: state.focusState.copyWith(
            remainingSeconds: state.focusState.remainingSeconds - 1,
          ),
        );
      } else {
        timer.cancel();
        state = state.copyWith(
          focusState: state.focusState.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            isCompleted: true,
          ),
          obtRecord: FounderRecord(
            id: state.obtRecord.id,
            date: state.obtRecord.date,
            oneBigThing: state.obtRecord.oneBigThing,
            oneBigThingCompleted: true,
            focusDurationMinutes: state.obtRecord.focusDurationMinutes + minutes,
          ),
        );
      }
    });
  }

  /// Pauses the running focus countdown.
  void pauseCountdown() {
    if (state.focusState.isRunning && !state.focusState.isPaused) {
      _countdownTimer?.cancel();
      state = state.copyWith(
        focusState: state.focusState.copyWith(isPaused: true, isRunning: false),
      );
    }
  }

  /// Resumes a paused countdown.
  void resumeCountdown() {
    if (state.focusState.isPaused) {
      state = state.copyWith(
        focusState: state.focusState.copyWith(isPaused: false, isRunning: true),
      );

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.focusState.remainingSeconds > 1) {
          state = state.copyWith(
            focusState: state.focusState.copyWith(
              remainingSeconds: state.focusState.remainingSeconds - 1,
            ),
          );
        } else {
          timer.cancel();
          state = state.copyWith(
            focusState: state.focusState.copyWith(
              remainingSeconds: 0,
              isRunning: false,
              isCompleted: true,
            ),
          );
        }
      });
    }
  }

  /// Resets the countdown back to idle state.
  void resetCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      focusState: const FocusCountdownState(
        totalSeconds: 45 * 60,
        remainingSeconds: 45 * 60,
      ),
    );
  }

  /// Marks the One Big Thing as manually completed.
  void toggleObtCompletion() {
    final updated = FounderRecord(
      id: state.obtRecord.id,
      date: state.obtRecord.date,
      oneBigThing: state.obtRecord.oneBigThing,
      oneBigThingCompleted: !state.obtRecord.oneBigThingCompleted,
      focusDurationMinutes: state.obtRecord.focusDurationMinutes,
    );
    state = state.copyWith(obtRecord: updated);
  }

  /// Executes and completes the active stacked routine.
  void completeNextRoutine() {
    final nextStack = state.nextRoutine.copyWith(
      isCompleted: true,
      triggerHabitTitle: '20m Lean Startup Validation',
      actionHabitTitle: '12 Pushups (Overload Compound)',
      stackFormula:
          'After I finish Lean Startup Validation, I will immediately execute 12 Pushups.',
      estimatedDurationMinutes: 5,
    );

    state = state.copyWith(
      habitsCompleted: (state.habitsCompleted + 1).clamp(0, state.habitsTotal),
      nextRoutine: nextStack,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}

/// Main Riverpod provider for Dashboard state.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
