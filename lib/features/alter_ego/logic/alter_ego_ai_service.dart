import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final alterEgoAiServiceProvider = Provider<AlterEgoAiService>((ref) {
  // TODO: Fetch API key from secure storage. Using a placeholder for now.
  const apiKey = 'YOUR_GEMINI_API_KEY';
  return AlterEgoAiService(apiKey: apiKey);
});

class AlterEgoGenerationResult {

  AlterEgoGenerationResult({
    required this.codename,
    required this.backstory,
    required this.ironRules,
  });

  factory AlterEgoGenerationResult.fromJson(Map<String, dynamic> json) {
    return AlterEgoGenerationResult(
      codename: json['codename'] ?? 'Unknown',
      backstory: json['backstory'] ?? '',
      ironRules: List<String>.from(json['ironRules'] ?? []),
    );
  }
  final String codename;
  final String backstory;
  final List<String> ironRules;
}

class AlterEgoAiService {

  AlterEgoAiService({required this.apiKey});
  final String apiKey;

  Future<AlterEgoGenerationResult> generateAlterEgo({
    required List<String> weaknesses,
    required String archetype,
    required String userName,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final prompt = '''
You are an expert psychological architect helping a user create an Alter Ego to overcome their weaknesses.
The user's real name is $userName.
Their self-identified weaknesses are: ${weaknesses.join(', ')}.
The chosen archetype for their Alter Ego is: $archetype.

Create an empowering, intense, and highly disciplined Alter Ego profile.
Return the response as a JSON object with the following schema:
{
  "codename": "The name of the Alter Ego",
  "backstory": "A 3-4 sentence powerful origin story of why this Alter Ego exists and how it destroys the user's weaknesses.",
  "ironRules": [
    "Rule 1",
    "Rule 2",
    "Rule 3",
    "Rule 4",
    "Rule 5"
  ]
}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(text);
        return AlterEgoGenerationResult.fromJson(jsonMap);
      } else {
        throw Exception('Received empty response from Gemini');
      }
    } catch (e) {
      throw Exception('Failed to generate Alter Ego: $e');
    }
  }
}
