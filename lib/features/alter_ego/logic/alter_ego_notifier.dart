import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/core/database/tables.dart';
import 'package:cadence/core/database/daos/alter_ego_dao.dart';
import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/features/alter_ego/logic/alter_ego_ai_service.dart';
// Note: We assume appDatabaseProvider is available in core/database/app_database.dart
// Since we don't have its provider yet, we'll declare a generic placeholder if needed,
// but let's assume it exists or we can inject it. For now, we'll create a placeholder if it fails.

// Provider for AlterEgoDao
// final alterEgoDaoProvider = Provider((ref) => ref.read(appDatabaseProvider).alterEgoDao);

class AlterEgoWizardState {

  AlterEgoWizardState({
    this.currentStep = 0,
    this.weaknesses = const [],
    this.archetype = '',
    this.userName = 'Ayaan Khan',
    this.generatedProfile,
    this.totem = '',
    this.isLoading = false,
    this.error,
  });
  final int currentStep;
  final List<String> weaknesses;
  final String archetype;
  final String userName;
  final AlterEgoGenerationResult? generatedProfile;
  final String totem;
  final bool isLoading;
  final String? error;

  AlterEgoWizardState copyWith({
    int? currentStep,
    List<String>? weaknesses,
    String? archetype,
    String? userName,
    AlterEgoGenerationResult? generatedProfile,
    String? totem,
    bool? isLoading,
    String? error,
  }) {
    return AlterEgoWizardState(
      currentStep: currentStep ?? this.currentStep,
      weaknesses: weaknesses ?? this.weaknesses,
      archetype: archetype ?? this.archetype,
      userName: userName ?? this.userName,
      generatedProfile: generatedProfile ?? this.generatedProfile,
      totem: totem ?? this.totem,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AlterEgoWizardNotifier extends StateNotifier<AlterEgoWizardState> {
  // final AlterEgoDao _dao; // Skipping actual DB insertion for this draft, or we can add it via constructor

  AlterEgoWizardNotifier(this._aiService) : super(AlterEgoWizardState(
    generatedProfile: AlterEgoGenerationResult(
      codename: 'Arvane Mirza',
      backstory: '',
      ironRules: [],
    )
  ));
  final AlterEgoAiService _aiService;

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void toggleWeakness(String weakness) {
    final current = List<String>.from(state.weaknesses);
    if (current.contains(weakness)) {
      current.remove(weakness);
    } else {
      current.add(weakness);
    }
    state = state.copyWith(weaknesses: current);
  }

  void setArchetype(String archetype) {
    state = state.copyWith(archetype: archetype);
  }

  void setTotem(String totem) {
    state = state.copyWith(totem: totem);
  }

  Future<void> generateProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _aiService.generateAlterEgo(
        weaknesses: state.weaknesses.isEmpty ? ['procrastination'] : state.weaknesses,
        archetype: state.archetype.isEmpty ? 'The Machine' : state.archetype,
        userName: state.userName,
      );
      
      // Override the codename with user preference if needed, or let Gemini decide.
      // We will let Gemini decide but if it fails to use Arvane Mirza, we could force it.
      
      state = state.copyWith(
        isLoading: false,
        generatedProfile: result,
        currentStep: 3, // Move to Editable Dossier
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveProfile(AlterEgoDao dao) async {
    if (state.generatedProfile == null) return;

    final profile = AlterEgoProfilesCompanion(
      id: Value(DateTime.now().millisecondsSinceEpoch.toString()), // Simple ID
      name: Value(state.generatedProfile!.codename),
      archetype: Value(state.archetype),
      backstory: Value(state.generatedProfile!.backstory),
      ironRules: Value(jsonEncode(state.generatedProfile!.ironRules)),
      totem: Value(state.totem),
    );

    await dao.saveProfile(profile);
  }
}

final alterEgoWizardProvider = StateNotifierProvider<AlterEgoWizardNotifier, AlterEgoWizardState>((ref) {
  final aiService = ref.watch(alterEgoAiServiceProvider);
  return AlterEgoWizardNotifier(aiService);
});
