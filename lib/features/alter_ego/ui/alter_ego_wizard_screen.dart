import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/features/alter_ego/logic/alter_ego_notifier.dart';

class AlterEgoWizardScreen extends ConsumerWidget {
  const AlterEgoWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alterEgoWizardProvider);
    final notifier = ref.read(alterEgoWizardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark industrial theme
      appBar: AppBar(
        title: const Text('Alter Ego Creator', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stepper(
        currentStep: state.currentStep,
        onStepContinue: () {
          if (state.currentStep == 2) {
            // Generate profile
            notifier.generateProfile();
          } else if (state.currentStep < 4) {
            notifier.setStep(state.currentStep + 1);
          }
        },
        onStepCancel: () {
          if (state.currentStep > 0) {
            notifier.setStep(state.currentStep - 1);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = state.currentStep == 4;
          final isGenerating = state.currentStep == 2 && state.isLoading;
          
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                if (!isLastStep && !isGenerating)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber, // High contrast amber
                      foregroundColor: Colors.black,
                    ),
                    child: Text(state.currentStep == 2 ? 'Generate AI Profile' : 'Continue'),
                  ),
                if (!isLastStep && !isGenerating && state.currentStep > 0)
                  const SizedBox(width: 12),
                if (!isLastStep && !isGenerating && state.currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Back'),
                  ),
                if (isGenerating)
                  const CircularProgressIndicator(color: Colors.amber),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Weaknesses', style: TextStyle(color: Colors.white)),
            content: _buildWeaknessChecklist(state, notifier),
            isActive: state.currentStep >= 0,
          ),
          Step(
            title: const Text('Archetype', style: TextStyle(color: Colors.white)),
            content: _buildArchetypeSelection(state, notifier),
            isActive: state.currentStep >= 1,
          ),
          Step(
            title: const Text('AI Generation', style: TextStyle(color: Colors.white)),
            content: const Text('Synthesizing Codename, Backstory, and Iron Rules using Gemini AI...', style: TextStyle(color: Colors.grey)),
            isActive: state.currentStep >= 2,
          ),
          Step(
            title: const Text('Dossier', style: TextStyle(color: Colors.white)),
            content: _buildDossier(state, notifier),
            isActive: state.currentStep >= 3,
          ),
          Step(
            title: const Text('Activation Pledge', style: TextStyle(color: Colors.white)),
            content: _buildActivationPledge(state, notifier, context),
            isActive: state.currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessChecklist(AlterEgoWizardState state, AlterEgoWizardNotifier notifier) {
    final options = ['Procrastination', 'Fear of Outreach', 'Lack of Workout Grit', 'Overthinking', 'Distraction'];
    return Column(
      children: options.map((w) {
        return CheckboxListTile(
          title: Text(w, style: const TextStyle(color: Colors.white70)),
          value: state.weaknesses.contains(w),
          onChanged: (val) => notifier.toggleWeakness(w),
          activeColor: Colors.amber,
          checkColor: Colors.black,
        );
      }).toList(),
    );
  }

  Widget _buildArchetypeSelection(AlterEgoWizardState state, AlterEgoWizardNotifier notifier) {
    final archetypes = ['The Machine', 'The Warrior', 'The Sovereign', 'The Rebel'];
    return Column(
      children: archetypes.map((a) {
        return RadioListTile<String>(
          title: Text(a, style: const TextStyle(color: Colors.white70)),
          value: a,
          groupValue: state.archetype,
          onChanged: (val) {
            if (val != null) notifier.setArchetype(val);
          },
          activeColor: Colors.amber,
        );
      }).toList(),
    );
  }

  Widget _buildDossier(AlterEgoWizardState state, AlterEgoWizardNotifier notifier) {
    if (state.generatedProfile == null) return const SizedBox.shrink();
    
    final profile = state.generatedProfile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Codename: ${profile.codename}', style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Backstory:', style: TextStyle(color: Colors.white54, fontSize: 16)),
        Text(profile.backstory, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        const Text('Iron Rules:', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ...profile.ironRules.map((rule) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.amber)),
              Expanded(child: Text(rule, style: const TextStyle(color: Colors.white))),
            ],
          ),
        )),
        const SizedBox(height: 20),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Physical Totem (e.g., Matte black ring)',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
          ),
          onChanged: (val) => notifier.setTotem(val),
        ),
      ],
    );
  }

  Widget _buildActivationPledge(AlterEgoWizardState state, AlterEgoWizardNotifier notifier, BuildContext context) {
    return Column(
      children: [
        const Text(
          'I pledge to invoke this Alter Ego when my weaknesses surface.',
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onLongPress: () async {
            // Note: In a real app we would pass the actual DAO instance here.
            // await notifier.saveProfile(dao);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alter Ego Activated!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
              ]
            ),
            child: const Text('HOLD TO ACTIVATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        )
      ],
    );
  }
}
