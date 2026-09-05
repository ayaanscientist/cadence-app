import 'package:flutter/material.dart';
import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Dynamic Next Routine card based on James Clear's Habit Stacking formula.
class NextRoutineCard extends StatelessWidget {
  const NextRoutineCard({
    super.key,
    required this.routine,
    required this.onExecuteRoutine,
  });

  final NextRoutineState routine;
  final VoidCallback onExecuteRoutine;

  @override
  Widget build(BuildContext context) {
    final isCompleted = routine.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.emerald.withValues(alpha: 0.5)
              : AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical Header Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.emeraldDim.withValues(alpha: 0.4)
                      : AppColors.amberDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted ? AppColors.emerald : AppColors.amber,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 13,
                      color: isCompleted ? AppColors.emerald : AppColors.amber,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ATOMIC HABIT STACK CHAIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isCompleted ? AppColors.emerald : AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '~${routine.estimatedDurationMinutes} MIN',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Trigger & Action Chain
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual connector line
              Column(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.slate),
                  Container(
                    width: 2,
                    height: 24,
                    color: AppColors.surfaceBorder,
                  ),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 12,
                    color: isCompleted ? AppColors.emerald : AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Habit Chain Descriptions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIGGER: ${routine.triggerHabitTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ACTION: ${routine.actionHabitTitle}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCompleted ? AppColors.emerald : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stack formula quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.slate),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${routine.stackFormula}"',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? AppColors.surfaceElevated
                    : AppColors.emeraldDim.withValues(alpha: 0.5),
                foregroundColor: isCompleted ? AppColors.textSecondary : AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isCompleted
                        ? AppColors.surfaceBorder
                        : AppColors.emerald.withValues(alpha: 0.8),
                  ),
                ),
                elevation: 0,
              ),
              icon: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                size: 18,
              ),
              label: Text(
                isCompleted ? 'ROUTINE COMPLETED • NEXT QUEUED' : 'EXECUTE ROUTINE',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              onPressed: onExecuteRoutine,
            ),
          ),
        ],
      ),
    );
  }
}
