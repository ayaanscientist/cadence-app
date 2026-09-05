import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure storage of sensitive values using
/// Android's hardware-backed KeyStore.
///
/// Primary use case: storing the user's Gemini API key.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _geminiApiKeyKey = 'gemini_api_key';

  /// Stores the Gemini API key securely.
  Future<void> setGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey);
  }

  /// Retrieves the stored Gemini API key, or `null` if not set.
  Future<String?> getGeminiApiKey() async {
    return _storage.read(key: _geminiApiKeyKey);
  }

  /// Checks whether a Gemini API key has been stored.
  Future<bool> hasGeminiApiKey() async {
    final key = await _storage.read(key: _geminiApiKeyKey);
    return key != null && key.isNotEmpty;
  }

  /// Removes the stored Gemini API key.
  Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }

  /// Removes all securely stored values.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
