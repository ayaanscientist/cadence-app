import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/features/habits/models/bad_habit.dart';
import 'package:cadence/core/database/daos/bad_habits_dao.dart';

/// Guided Craving SOS Delay Timer with Box Breathing Visualizer (Urge Surfing).
class CravingSosScreen extends StatefulWidget {
  const CravingSosScreen({
    super.key,
    required this.badHabit,
    this.badHabitsDao,
  });

  final BadHabit badHabit;
  final BadHabitsDao? badHabitsDao;

  @override
  State<CravingSosScreen> createState() => _CravingSosScreenState();
}

class _CravingSosScreenState extends State<CravingSosScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 10 * 60; // 10 minutes delay
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;

  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // Box Breathing: 4s Inhale, 4s Hold, 4s Exhale, 4s Hold (16s cycle)
  Timer? _breathPhaseTimer;
  int _breathSecond = 0;
  String _breathPhase = 'INHALE';
  Color _phaseColor = AppColors.cyan;

  @override
  void initState() {
    super.initState();

    // 1. Setup breathing animation
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _startTimers();
  }

  void _startTimers() {
    // 10-minute urge delay countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _onDelayCompleted();
      }
    });

    // Guided 16-second box breathing cycle
    _breathController.forward();
    _breathPhaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _breathSecond = (_breathSecond + 1) % 16;
        if (_breathSecond < 4) {
          _breathPhase = 'INHALE DEEP';
          _phaseColor = AppColors.cyan;
          if (_breathSecond == 0) _breathController.forward();
        } else if (_breathSecond < 8) {
          _breathPhase = 'HOLD BREATH';
          _phaseColor = AppColors.indigo;
        } else if (_breathSecond < 12) {
          _breathPhase = 'EXHALE SLOWLY';
          _phaseColor = AppColors.emerald;
          if (_breathSecond == 8) _breathController.reverse();
        } else {
          _breathPhase = 'PAUSE & EMPTY';
          _phaseColor = AppColors.slate;
        }
      });
    });
  }

  void _onDelayCompleted() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('10-Minute Delay Complete!'),
        content: const Text(
          'The neurochemical craving spike has peaked and subsided. You have successfully created space between impulse and action.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () {
              Navigator.pop(ctx);
              _handleSurfedUrge();
            },
            child: const Text('I SURFED THE URGE'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSurfedUrge() async {
    if (widget.badHabitsDao != null) {
      await widget.badHabitsDao!.recordCravingResisted(widget.badHabit.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Craving conquered! Streak preserved & resisted count incremented.'),
        backgroundColor: AppColors.emeraldDim,
      ),
    );
    Navigator.pop(context, true);
  }

  void _showRelapseDialog() {
    final triggerController = TextEditingController(text: 'Stress');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.healing_rounded, color: AppColors.amber),
            SizedBox(width: 8),
            Text('Non-Judgmental Reflection'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relapse is data, not defeat. Document the trigger to fortify your system next time.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: triggerController,
                decoration: const InputDecoration(
                  labelText: 'Primary Trigger',
                  hintText: 'e.g. Work Stress, Fatigue, Social Setting',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Context / Lesson Learned',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redDim,
              foregroundColor: AppColors.red,
            ),
            onPressed: () async {
              if (widget.badHabitsDao != null) {
                await widget.badHabitsDao!.recordRelapse(
                  badHabitId: widget.badHabit.id,
                  trigger: triggerController.text.trim(),
                  notes: notesController.text.trim(),
                );
              }
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context, false);
              }
            },
            child: const Text('RECORD RELAPSE & RESET CLOCK'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathPhaseTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'URGE SURFING // SOS DELAY',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Habit Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  'RESISTING: ${widget.badHabit.title.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Urge Surfing explanation
              const Text(
                'Dopamine cravings are like ocean waves — they crest at 10 minutes and fade. Inhale calm, exhale the urge.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Breathing Visualizer
              AnimatedBuilder(
                animation: _breathAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulsing aura
                      Container(
                        width: 220 * _breathAnimation.value,
                        height: 220 * _breathAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _phaseColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: _phaseColor.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      ),
                      // Core Breathing Orb
                      Container(
                        width: 150 * _breathAnimation.value,
                        height: 150 * _breathAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _phaseColor.withValues(alpha: 0.8),
                              _phaseColor.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      // Inner Phase Label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _breathPhase,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formattedTime,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),

              // Victory Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldDim,
                    foregroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.emerald, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.verified_rounded, size: 20),
                  label: const Text(
                    'I SURFED THE URGE (STREAK INTACT)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: _handleSurfedUrge,
                ),
              ),
              const SizedBox(height: 12),

              // Non-Judgmental Relapse Audit Trigger
              TextButton(
                onPressed: _showRelapseDialog,
                child: const Text(
                  'I Gave In — Log Relapse & Reset',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
