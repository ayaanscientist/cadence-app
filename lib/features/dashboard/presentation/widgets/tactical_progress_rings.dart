import 'package:flutter/material.dart';
import 'package:cadence/core/constants/app_colors.dart';

/// Industrial circular progress indicators for Habits, Nutrition, and Physical Overload.
class TacticalProgressRings extends StatelessWidget {
  const TacticalProgressRings({
    super.key,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.caloriesConsumed,
    required this.calorieTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.exerciseName,
    required this.exerciseCompletedReps,
    required this.exerciseTargetReps,
    required this.exerciseIncrementRate,
  });

  final int habitsCompleted;
  final int habitsTotal;
  final int caloriesConsumed;
  final int calorieTarget;
  final int proteinConsumed;
  final int proteinTarget;
  final String exerciseName;
  final int exerciseCompletedReps;
  final int exerciseTargetReps;
  final String exerciseIncrementRate;

  @override
  Widget build(BuildContext context) {
    final habitsFraction = habitsTotal > 0 ? (habitsCompleted / habitsTotal).clamp(0.0, 1.0) : 0.0;
    final calorieFraction = calorieTarget > 0 ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.0) : 0.0;
    final exerciseFraction = exerciseTargetReps > 0
        ? (exerciseCompletedReps / exerciseTargetReps).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 14, color: AppColors.slate),
              SizedBox(width: 8),
              Text(
                'DAILY COMPOUNDING GAUGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Circular Indicators in a grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Daily Habits Ring
              _buildProgressGauge(
                title: 'HABITS',
                valueText: '$habitsCompleted/$habitsTotal',
                subText: '${(habitsFraction * 100).toInt()}%',
                progress: habitsFraction,
                ringColor: AppColors.emerald,
                icon: Icons.check_circle_outline,
              ),

              // 2. Nutrition / Calorie & Protein Ring
              _buildProgressGauge(
                title: 'ENERGY',
                valueText: '${(calorieFraction * 100).toInt()}%',
                subText: '${caloriesConsumed}k',
                secondarySubText: '${proteinConsumed}g P',
                progress: calorieFraction,
                ringColor: AppColors.amber,
                icon: Icons.bolt_outlined,
              ),

              // 3. Physical Overload Ring
              _buildProgressGauge(
                title: 'OVERLOAD',
                valueText: '$exerciseCompletedReps/$exerciseTargetReps',
                subText: exerciseName,
                progress: exerciseFraction,
                ringColor: AppColors.cyan,
                icon: Icons.fitness_center_rounded,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 10),

          // Micro status footnote
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Physical Overload Formula: $exerciseIncrementRate',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressGauge({
    required String title,
    required String valueText,
    required String subText,
    String? secondarySubText,
    required double progress,
    required Color ringColor,
    required IconData icon,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Track
              const CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.surfaceElevated,
                ),
              ),
              // Dynamic Fill
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              ),
              // Center Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: ringColor),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ringColor,
          ),
        ),
        if (secondarySubText != null) ...[
          Text(
            secondarySubText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
