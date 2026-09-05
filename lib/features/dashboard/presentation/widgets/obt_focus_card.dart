import 'package:flutter/material.dart';
import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/features/founder/models/founder_record.dart';
import 'package:cadence/features/dashboard/presentation/providers/dashboard_providers.dart';

/// "One Big Thing" high-priority focus card with direct countdown launch.
class ObtFocusCard extends StatelessWidget {
  const ObtFocusCard({
    super.key,
    required this.record,
    required this.focusState,
    required this.onLaunchCountdown,
    required this.onPauseCountdown,
    required this.onResumeCountdown,
    required this.onResetCountdown,
    required this.onToggleCompleted,
  });

  final FounderRecord record;
  final FocusCountdownState focusState;
  final VoidCallback onLaunchCountdown;
  final VoidCallback onPauseCountdown;
  final VoidCallback onResumeCountdown;
  final VoidCallback onResetCountdown;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final isCompleted = record.oneBigThingCompleted;
    final isRunning = focusState.isRunning;
    final isPaused = focusState.isPaused;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.emerald.withOpacity(0.5)
              : (isRunning ? AppColors.cyan : AppColors.surfaceBorder),
          width: isRunning ? 1.5 : 1.0,
        ),
        boxShadow: isRunning
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.emeraldDim.withOpacity(0.4)
                      : AppColors.cyanDim.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted ? AppColors.emerald : AppColors.cyan,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.radar_rounded,
                      size: 13,
                      color: isCompleted ? AppColors.emerald : AppColors.cyan,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ONE BIG THING (OBT)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isCompleted ? AppColors.emerald : AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Checkbox Toggle
              InkWell(
                onTap: onToggleCompleted,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? AppColors.emerald : AppColors.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: isCompleted ? Colors.black : Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // OBT Title
          Text(
            record.oneBigThing,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.emerald,
            ),
          ),
          const SizedBox(height: 16),

          // Live Timer or Idle Launch State
          if (isRunning || isPaused) ...[
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: focusState.progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 12),

            // Live Countdown Row + Control Buttons
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: isPaused ? AppColors.amber : AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Text(
                  focusState.formattedTimer,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isPaused ? AppColors.amber : AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isPaused ? 'PAUSED' : 'DEEP WORK FOCUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isPaused ? AppColors.amber : AppColors.slate,
                  ),
                ),
                const Spacer(),

                // Pause / Resume Button
                IconButton(
                  icon: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: isPaused ? 'Resume' : 'Pause',
                  onPressed: isPaused ? onResumeCountdown : onPauseCountdown,
                ),

                // Reset Button
                IconButton(
                  icon: const Icon(Icons.stop_rounded, color: AppColors.textMuted),
                  tooltip: 'Reset timer',
                  onPressed: onResetCountdown,
                ),
              ],
            ),
          ] else ...[
            // Direct Launch Action Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? AppColors.surfaceElevated
                          : AppColors.cyanDim.withOpacity(0.4),
                      foregroundColor: isCompleted ? AppColors.textSecondary : AppColors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isCompleted
                              ? AppColors.surfaceBorder
                              : AppColors.cyan.withOpacity(0.7),
                        ),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      isCompleted ? Icons.check_circle_outline : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isCompleted
                          ? 'OBT COMPLETED (${record.focusDurationFormatted})'
                          : 'LAUNCH 45M DEEP WORK',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    onPressed: isCompleted ? null : onLaunchCountdown,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
