import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/features/physical/logic/workout_session_notifier.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSessionProvider);
    final notifier = ref.read(workoutSessionProvider.notifier);
    
    final duration = state.sessionStartTime != null 
        ? DateTime.now().difference(state.sessionStartTime!) 
        : const Duration(seconds: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('SESSION COMPLETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 100),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBlock('ENERGY LOSS', '${state.totalCaloriesBurned} kcal', Colors.orangeAccent),
                  Container(width: 1, height: 50, color: Colors.grey[800]),
                  _buildStatBlock('DURATION', '${duration.inMinutes}m ${duration.inSeconds % 60}s', Colors.cyanAccent),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('EXERCISES COMPLETED', style: TextStyle(color: Colors.grey, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: state.exercisesQueue.length,
                itemBuilder: (context, index) {
                  final ex = state.exercisesQueue[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fitness_center, color: Colors.amber),
                    title: Text(ex.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text(
                      ex.defaultDurationSec > 0 ? '${ex.defaultDurationSec}s' : 'x${ex.defaultReps}',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                notifier.finishSummary();
                // In a real app, Navigator.of(context).pop();
              },
              child: const Text('FINISH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
