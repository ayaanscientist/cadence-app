import 'package:flutter/material.dart';
import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/core/database/tables.dart';

/// Header section displaying current date, system status, and streak badge.
class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.formattedDate,
    required this.systemStatus,
    required this.streakDays,
    required this.streakStatus,
  });

  final String formattedDate;
  final String systemStatus;
  final int streakDays;
  final HabitStatus streakStatus;

  @override
  Widget build(BuildContext context) {
    final isAtRisk = streakStatus == HabitStatus.atRisk;
    final badgeColor = isAtRisk ? AppColors.amber : AppColors.emerald;
    final badgeBg = isAtRisk ? AppColors.amberDim.withValues(alpha: 0.35) : AppColors.emeraldDim.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: System status dot + label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                systemStatus,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.slate,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.offline_bolt_rounded,
                size: 16,
                color: AppColors.emerald,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle row: Current Date + Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ATOMIC OPERATING CADENCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              // Tactical Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAtRisk ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
                      size: 18,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$streakDays DAYS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Never Miss Twice alert banner if at risk
          if (isAtRisk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amberDim.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NEVER MISS TWICE: Complete today\'s stack to preserve streak.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
