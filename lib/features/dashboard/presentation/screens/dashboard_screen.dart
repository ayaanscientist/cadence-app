import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cadence/features/dashboard/presentation/widgets/header_section.dart';
import 'package:cadence/features/dashboard/presentation/widgets/obt_focus_card.dart';
import 'package:cadence/features/dashboard/presentation/widgets/tactical_progress_rings.dart';
import 'package:cadence/features/dashboard/presentation/widgets/next_routine_card.dart';
import 'package:cadence/core/services/alarm_service.dart';
import 'package:cadence/features/dashboard/ui/energy_balance_widget.dart';
import 'package:cadence/features/alter_ego/ui/alter_ego_wizard_screen.dart';
import 'package:cadence/features/physical/ui/active_workout_screen.dart';

/// Main Dashboard Screen for AtomicOS.
///
/// Serves as the central high-contrast, offline command center.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Text(
                'ATOMIC // OS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Alarm Status Quick Action
          IconButton(
            icon: const Icon(Icons.alarm_on_rounded, color: AppColors.emerald, size: 22),
            tooltip: 'Configured Exact Alarms',
            onPressed: () => _showAlarmSheet(context),
          ),
          // AI Assistant Quick Action
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 22),
            tooltip: 'Gemini Assistant',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline Gemini Copilot ready for briefing.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emerald,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            // Re-read local state / sync if needed
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Section
                HeaderSection(
                  formattedDate: state.formattedDate,
                  systemStatus: state.systemStatus,
                  streakDays: state.streakDays,
                  streakStatus: state.streakStatus,
                ),
                const SizedBox(height: 16),

                // 2. One Big Thing (OBT) Card with Direct Countdown Launch
                ObtFocusCard(
                  record: state.obtRecord,
                  focusState: state.focusState,
                  onLaunchCountdown: () => notifier.launchDeepWorkCountdown(minutes: 45),
                  onPauseCountdown: () => notifier.pauseCountdown(),
                  onResumeCountdown: () => notifier.resumeCountdown(),
                  onResetCountdown: () => notifier.resetCountdown(),
                  onToggleCompleted: () => notifier.toggleObtCompletion(),
                ),
                const SizedBox(height: 16),

                // 3. Circular Progress Indicators (Tactical Compounding Gauges)
                TacticalProgressRings(
                  habitsCompleted: state.habitsCompleted,
                  habitsTotal: state.habitsTotal,
                  caloriesConsumed: state.caloriesConsumed,
                  calorieTarget: state.calorieTarget,
                  proteinConsumed: state.proteinConsumed,
                  proteinTarget: state.proteinTarget,
                  exerciseName: state.exerciseName,
                  exerciseCompletedReps: state.exerciseCompletedReps,
                  exerciseTargetReps: state.exerciseTargetReps,
                  exerciseIncrementRate: state.exerciseIncrementRate,
                ),
                const SizedBox(height: 16),

                // 4. Dynamic Next Routine Card (Habit Stacking Chain)
                NextRoutineCard(
                  routine: state.nextRoutine,
                  onExecuteRoutine: () {
                    notifier.completeNextRoutine();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Habit stack completed! Next routine queued.'),
                        backgroundColor: AppColors.emeraldDim,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 5. Energy Balance Ledger
                EnergyBalanceWidget(
                  caloriesConsumed: state.caloriesConsumed,
                  bmr: 1850.0, // Hardcoded for demo/preview
                  activeEnergyBurned: 320, // Hardcoded for demo/preview
                ),
                const SizedBox(height: 16),

                // Quick Launch Buttons for New Features
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Start Workout'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.cyan,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.psychology),
                        label: const Text('Alter Ego'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlterEgoWizardScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays active offline exact alarm schedules.
  void _showAlarmSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: AppColors.emerald, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'SCHEDULED EXACT ALARMS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldDim.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emerald),
                    ),
                    child: const Text(
                      'BOOT ARMED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAlarmItem(
                type: 'Meditation Alert',
                time: '07:00 AM',
                channel: 'Exact wake-up & interval chime',
                color: AppColors.indigo,
              ),
              const Divider(color: AppColors.surfaceBorder, height: 16),
              _buildAlarmItem(
                type: 'Wind-Down Sleep Alert',
                time: '10:00 PM',
                channel: 'Screen dimming & meditation prep',
                color: AppColors.amber,
              ),
              const Divider(color: AppColors.surfaceBorder, height: 16),
              _buildAlarmItem(
                type: 'Morning Wake-Up Call',
                time: '06:30 AM',
                channel: 'High-priority native AlarmManager',
                color: AppColors.emerald,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlarmItem({
    required String type,
    required String time,
    required String channel,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              channel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
