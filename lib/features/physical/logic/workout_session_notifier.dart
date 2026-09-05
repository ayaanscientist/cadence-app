import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cadence/core/database/database.dart';
import 'package:cadence/features/physical/logic/biometric_calculator.dart';
import 'package:just_audio/just_audio.dart';

// Assuming we have providers for the DAOs
// final workoutDaoProvider = Provider<WorkoutDao>((ref) => ...);
// final userBiometricsProvider = FutureProvider<UserBiometricEntry?>((ref) => ...);

enum WorkoutStateStatus { idle, exerciseActive, restInterval, sessionSummary }

class WorkoutSessionState {

  WorkoutSessionState({
    this.status = WorkoutStateStatus.idle,
    this.sessionId,
    this.exercisesQueue = const [],
    this.currentExerciseIndex = 0,
    this.restSecondsRemaining = 0,
    this.totalCaloriesBurned = 0,
    this.sessionStartTime,
    this.userWeightKg = 75.0,
  });
  final WorkoutStateStatus status;
  final String? sessionId;
  final List<ExerciseEntry> exercisesQueue;
  final int currentExerciseIndex;
  final int restSecondsRemaining;
  final int totalCaloriesBurned;
  final DateTime? sessionStartTime;
  
  // Biometric fallback
  final double userWeightKg;

  ExerciseEntry? get currentExercise => 
      (currentExerciseIndex < exercisesQueue.length) 
          ? exercisesQueue[currentExerciseIndex] 
          : null;

  WorkoutSessionState copyWith({
    WorkoutStateStatus? status,
    String? sessionId,
    List<ExerciseEntry>? exercisesQueue,
    int? currentExerciseIndex,
    int? restSecondsRemaining,
    int? totalCaloriesBurned,
    DateTime? sessionStartTime,
    double? userWeightKg,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      exercisesQueue: exercisesQueue ?? this.exercisesQueue,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      userWeightKg: userWeightKg ?? this.userWeightKg,
    );
  }
}

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {

  WorkoutSessionNotifier(
    // this._dao,
    {double initialWeight = 75.0}
  ) : super(WorkoutSessionState(userWeightKg: initialWeight));
  // final WorkoutDao _dao;
  // final GamificationDao _gamificationDao;
  Timer? _restTimer;
  DateTime? _exerciseStartTime;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> startSession(List<ExerciseEntry> exercises) async {
    if (exercises.isEmpty) return;
    
    // In real implementation:
    // final sessionId = await _dao.startSession();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    state = state.copyWith(
      status: WorkoutStateStatus.exerciseActive,
      sessionId: sessionId,
      exercisesQueue: exercises,
      currentExerciseIndex: 0,
      totalCaloriesBurned: 0,
      sessionStartTime: DateTime.now(),
    );
    _exerciseStartTime = DateTime.now();
  }

  void completeExercise() async {
    final currentEx = state.currentExercise;
    if (currentEx == null || state.sessionId == null) return;

    final durationSec = DateTime.now().difference(_exerciseStartTime ?? DateTime.now()).inSeconds;
    
    // Calculate burned calories using the physical engine
    final caloriesBurned = BiometricCalculator.calculateActiveCalorieBurn(
      metValue: currentEx.metValue,
      weightKg: state.userWeightKg,
      durationMinutes: durationSec / 60.0,
    );

    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // In real implementation:
    /*
    await _dao.logCompletedExercise(
      sessionId: state.sessionId!,
      exerciseId: currentEx.id,
      repsDone: currentEx.defaultReps,
      durationSec: durationSec,
      caloriesBurnedKcal: caloriesBurned,
      todayDateString: todayString,
    );
    
    // Grant 50 XP per completed set
    await _gamificationDao.grantXp(50);
    */

    final newTotal = state.totalCaloriesBurned + caloriesBurned;
    final isLast = state.currentExerciseIndex >= state.exercisesQueue.length - 1;

    if (isLast) {
      // Finish session
      // await _dao.endSession(state.sessionId!);
      state = state.copyWith(
        status: WorkoutStateStatus.sessionSummary,
        totalCaloriesBurned: newTotal,
      );
    } else {
      // Go to rest
      state = state.copyWith(
        status: WorkoutStateStatus.restInterval,
        restSecondsRemaining: 30, // 30s default rest
        totalCaloriesBurned: newTotal,
      );
      _startRestTimer();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.restSecondsRemaining > 0) {
        state = state.copyWith(restSecondsRemaining: state.restSecondsRemaining - 1);
        
        // Play chime cue at 3, 2, 1 seconds remaining
        if (state.restSecondsRemaining > 0 && state.restSecondsRemaining <= 3) {
          try {
            await _audioPlayer.setAsset('assets/audio/chime_short.mp3');
            _audioPlayer.play();
          } catch (_) {
            // Ignore missing asset in demo
          }
        }
      } else {
        skipRest();
      }
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(
      status: WorkoutStateStatus.exerciseActive,
      currentExerciseIndex: state.currentExerciseIndex + 1,
    );
    _exerciseStartTime = DateTime.now();
  }

  void addRestTime(int seconds) {
    state = state.copyWith(restSecondsRemaining: state.restSecondsRemaining + seconds);
  }

  void finishSummary() {
    state = WorkoutSessionState(userWeightKg: state.userWeightKg); // Reset to idle
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Dummy provider for UI testing
final workoutSessionProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  return WorkoutSessionNotifier();
});
