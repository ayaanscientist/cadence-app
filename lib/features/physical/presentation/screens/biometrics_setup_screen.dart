import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/core/database/daos/biometrics_dao.dart';
import 'package:cadence/features/physical/logic/biometric_calculator.dart';
import 'package:cadence/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Profile & Biometric Setup Screen for Metabolic Calculations and Sleep Target configuration.
class BiometricsSetupScreen extends ConsumerStatefulWidget {
  const BiometricsSetupScreen({
    super.key,
    this.biometricsDao,
  });

  final BiometricsDao? biometricsDao;

  @override
  ConsumerState<BiometricsSetupScreen> createState() =>
      _BiometricsSetupScreenState();
}

class _BiometricsSetupScreenState extends ConsumerState<BiometricsSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;

  String _gender = 'male';
  double _baselineSleepHours = 8.0;
  String _activityLevel = 'moderate';
  String _goal = 'maintenance';

  // Live calculated preview values
  double _liveBmr = 0.0;
  double _liveTdee = 0.0;
  int _liveTargetCalories = 2000;
  int _liveTargetProtein = 140;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '28');
    _heightController = TextEditingController(text: '180');
    _weightController = TextEditingController(text: '78.5');
    _targetWeightController = TextEditingController(text: '75.0');

    _ageController.addListener(_recalculateLive);
    _heightController.addListener(_recalculateLive);
    _weightController.addListener(_recalculateLive);
    _targetWeightController.addListener(_recalculateLive);

    _recalculateLive();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    if (widget.biometricsDao != null) {
      final existing = await widget.biometricsDao!.getUserBiometrics();
      if (existing != null && mounted) {
        setState(() {
          _ageController.text = existing.age.toString();
          _heightController.text = existing.heightCm.toStringAsFixed(0);
          _weightController.text = existing.weightKg.toStringAsFixed(1);
          _targetWeightController.text =
              existing.targetWeightKg.toStringAsFixed(1);
          _gender = existing.gender;
          _baselineSleepHours = existing.baselineSleepNeedHours;
          _activityLevel = existing.activityLevel;
          _goal = existing.goal;
        });
        _recalculateLive();
      }
    }
  }

  void _recalculateLive() {
    final age = int.tryParse(_ageController.text) ?? 28;
    final height = double.tryParse(_heightController.text) ?? 180.0;
    final weight = double.tryParse(_weightController.text) ?? 78.5;

    final bmr = BiometricCalculator.calculateBmr(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _gender,
    );

    final tdee = BiometricCalculator.calculateTdee(
      bmr: bmr,
      activityLevel: _activityLevel,
    );

    final calories = BiometricCalculator.calculateTargetCalories(
      tdee: tdee,
      goal: _goal,
    );

    final protein = BiometricCalculator.calculateProteinTarget(
      weightKg: weight,
      gramsPerKg: 1.8,
    );

    setState(() {
      _liveBmr = bmr;
      _liveTdee = tdee;
      _liveTargetCalories = calories;
      _liveTargetProtein = protein;
    });
  }

  Future<void> _saveBiometrics() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageController.text.trim());
    final height = double.parse(_heightController.text.trim());
    final weight = double.parse(_weightController.text.trim());
    final targetWeight = double.parse(_targetWeightController.text.trim());

    // 1. Save to SQLite via DAO if provided
    if (widget.biometricsDao != null) {
      await widget.biometricsDao!.upsertUserBiometrics(
        age: age,
        gender: _gender,
        heightCm: height,
        weightKg: weight,
        targetWeightKg: targetWeight,
        baselineSleepNeedHours: _baselineSleepHours,
        activityLevel: _activityLevel,
        goal: _goal,
      );
    }

    // 2. Instantly update main Dashboard state with recalculated macros
    ref.read(dashboardProvider.notifier).state =
        ref.read(dashboardProvider).copyWith(
              calorieTarget: _liveTargetCalories,
              proteinTarget: _liveTargetProtein,
            );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Metabolic baseline saved! Targets updated: $_liveTargetCalories kcal • ${_liveTargetProtein}g protein',
        ),
        backgroundColor: AppColors.emeraldDim,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'METABOLIC & SLEEP PROFILE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Live Calculation Preview Card ───────────────────────────
                _buildLivePreviewCard(),
                const SizedBox(height: 24),

                // ── Gender Selection ────────────────────────────────────────
                _buildSectionLabel('BIOLOGICAL SEX (Mifflin-St Jeor)'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('MALE (+5)')),
                    ButtonSegment(value: 'female', label: Text('FEMALE (-161)')),
                  ],
                  selected: {_gender},
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.surfaceElevated;
                      }
                      return AppColors.surface;
                    }),
                    foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
                  ),
                  onSelectionChanged: (set) {
                    setState(() => _gender = set.first);
                    _recalculateLive();
                  },
                ),
                const SizedBox(height: 20),

                // ── Age, Height, Current Weight, Target Weight ──────────────
                _buildSectionLabel('PHYSICAL BIOMETRICS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _ageController,
                        label: 'Age',
                        suffix: 'yrs',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _heightController,
                        label: 'Height',
                        suffix: 'cm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _weightController,
                        label: 'Current Weight',
                        suffix: 'kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _targetWeightController,
                        label: 'Target Weight',
                        suffix: 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Activity Level & Goal ───────────────────────────────────
                _buildSectionLabel('ACTIVITY LEVEL & BODY GOAL'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _activityLevel,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: _inputDecoration('Activity Multiplier'),
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('Sedentary (1.2x) — Desk Job'),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text('Lightly Active (1.375x) — 1-3 d/wk'),
                    ),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderately Active (1.55x) — 3-5 d/wk'),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Very Active (1.725x) — 6-7 d/wk'),
                    ),
                    DropdownMenuItem(
                      value: 'veryActive',
                      child: Text('Extremely Active (1.9x) — Heavy Labor'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _activityLevel = val);
                      _recalculateLive();
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: _inputDecoration('Primary Body Goal'),
                  items: const [
                    DropdownMenuItem(
                      value: 'fatLoss',
                      child: Text('Fat Loss (-500 kcal Deficit)'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance (Equal to TDEE)'),
                    ),
                    DropdownMenuItem(
                      value: 'muscleGain',
                      child: Text('Lean Muscle Gain (+300 kcal Surplus)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _goal = val);
                      _recalculateLive();
                    }
                  },
                ),
                const SizedBox(height: 24),

                // ── Sleep Need Target Slider ────────────────────────────────
                _buildSectionLabel(
                    'BASELINE SLEEP NEED: ${_baselineSleepHours.toStringAsFixed(1)} HOURS'),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.indigo,
                    inactiveTrackColor: AppColors.surfaceElevated,
                    thumbColor: AppColors.indigo,
                    overlayColor: AppColors.indigo.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _baselineSleepHours,
                    min: 6.0,
                    max: 10.0,
                    divisions: 8,
                    label: '${_baselineSleepHours.toStringAsFixed(1)} hrs',
                    onChanged: (val) {
                      setState(() => _baselineSleepHours = val);
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // ── Save Button ─────────────────────────────────────────────
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldDim,
                    foregroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side:
                          const BorderSide(color: AppColors.emerald, width: 1.5),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'SAVE & RECALCULATE DASHBOARD TARGETS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: _saveBiometrics,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard() {
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
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.cyan),
              SizedBox(width: 8),
              Text(
                'LIVE METABOLIC PROJECTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('BMR', '${_liveBmr.round()} kcal', AppColors.slate),
              _buildMetric('TDEE', '${_liveTdee.round()} kcal', AppColors.slate),
              _buildMetric('TARGET', '$_liveTargetCalories kcal', AppColors.amber),
              _buildMetric('PROTEIN', '${_liveTargetProtein}g', AppColors.emerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.slate,
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label, suffix: suffix),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Required';
        final num = double.tryParse(val.trim());
        if (num == null || num <= 0) return 'Invalid';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cyan),
      ),
    );
  }
}
