import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/features/physical/logic/workout_session_notifier.dart';
import 'package:cadence/features/physical/ui/workout_summary_screen.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSessionProvider);
    final notifier = ref.read(workoutSessionProvider.notifier);

    // If summary, redirect (In real app, we might use routing, but for demo we can return a view)
    if (state.status == WorkoutStateStatus.sessionSummary) {
      return const WorkoutSummaryScreen();
    }

    if (state.status == WorkoutStateStatus.idle) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: Text('No active workout', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          state.status == WorkoutStateStatus.exerciseActive ? 'ACTIVE SET' : 'REST',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: state.status == WorkoutStateStatus.exerciseActive 
        ? _buildExerciseActive(state, notifier)
        : _buildRestInterval(state, notifier),
    );
  }

  Widget _buildExerciseActive(WorkoutSessionState state, WorkoutSessionNotifier notifier) {
    final ex = state.currentExercise;
    if (ex == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder for exercise animation/icon
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: const Icon(Icons.fitness_center, size: 80, color: Colors.amber),
        ),
        const SizedBox(height: 40),
        Text(
          ex.name.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          ex.defaultDurationSec > 0 
            ? '${ex.defaultDurationSec} SECONDS' 
            : '${ex.defaultReps} REPS',
          style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 70),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => notifier.completeExercise(),
            child: const Text('COMPLETE & NEXT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildRestInterval(WorkoutSessionState state, WorkoutSessionNotifier notifier) {
    final nextEx = state.currentExercise;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: state.restSecondsRemaining / 30.0, // Assuming max is 30 for UI scaling
                strokeWidth: 8,
                backgroundColor: Colors.grey[900],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
            Text(
              '${state.restSecondsRemaining}s',
              style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (nextEx != null) ...[
          const Text('UP NEXT:', style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text(nextEx.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () => notifier.addRestTime(15),
              child: const Text('+15s', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () => notifier.skipRest(),
              child: const Text('SKIP REST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ],
    );
  }
}
