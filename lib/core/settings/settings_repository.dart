import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'package:cadence/core/database/daos/settings_dao.dart';

/// Central repository managing dynamic application configurations and settings.
class SettingsRepository {
  SettingsRepository({required SettingsDao settingsDao}) : _dao = settingsDao;

  final SettingsDao _dao;

  // System Keys
  static const String keyOverloadRate = 'setting_overload_increment_rate';
  static const String keyCustomAlarmAudio = 'setting_custom_alarm_audio_path';
  static const String keyDndAutoToggle = 'setting_dnd_auto_toggle';
  static const String keyAppBlockingEnabled = 'setting_app_blocking_enabled';
  static const String keyBlockedAppPackages = 'setting_blocked_app_packages';
  static const String keyDarkThemeMode = 'setting_dark_theme_mode';

  // Defaults
  static const double defaultOverloadRate = 0.01; // 1%
  static const List<String> defaultBlockedPackages = [
    'com.instagram.android',
    'com.twitter.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.google.android.youtube',
    'com.reddit.frontpage',
  ];

  // ── 1. Progressive Overload Increment Slider ──────────────────────────

  /// Gets the progressive overload daily compounding rate (0.01 to 0.10).
  Future<double> getOverloadIncrementRate() async {
    final val = await _dao.getSetting(keyOverloadRate);
    if (val != null) {
      final parsed = double.tryParse(val);
      if (parsed != null) {
        return parsed.clamp(0.01, 0.10);
      }
    }
    return defaultOverloadRate;
  }

  /// Sets the progressive overload daily compounding rate (0.01 to 0.10).
  Future<void> setOverloadIncrementRate(double rate) async {
    final clamped = rate.clamp(0.01, 0.10);
    await _dao.setSetting(keyOverloadRate, clamped.toStringAsFixed(3));
  }

  /// Reactive stream for real-time slider updates in UI.
  Stream<double> watchOverloadIncrementRate() {
    return _dao.watchSetting(keyOverloadRate).map((val) {
      if (val != null) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed.clamp(0.01, 0.10);
      }
      return defaultOverloadRate;
    });
  }

  // ── 2. Custom Audio File Picker for Alarms ─────────────────────────────

  /// Opens the native system file picker to select a custom local audio file
  /// (.mp3, .wav, .ogg, .m4a) for alarms.
  ///
  /// Persists the selected path in [AppSettings] and returns it.
  Future<String?> pickAndSetCustomAlarmAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _dao.setSetting(keyCustomAlarmAudio, path);
        return path;
      }
    } catch (_) {
      // Fallback for non-supported or cancelled picker
    }
    return null;
  }

  /// Gets the currently configured custom alarm audio path, if any.
  Future<String?> getCustomAlarmAudioPath() async {
    return _dao.getSetting(keyCustomAlarmAudio);
  }

  /// Clears the custom alarm audio setting (reverts to bundled assets).
  Future<void> clearCustomAlarmAudio() async {
    await _dao.deleteSetting(keyCustomAlarmAudio);
  }

  // ── 3. Phone Focus & Control Config ───────────────────────────────────

  /// Whether DND mode is automatically activated during Deep Work sessions.
  Future<bool> isDndAutoToggleEnabled() async {
    final val = await _dao.getSetting(keyDndAutoToggle);
    return val == 'true';
  }

  Future<void> setDndAutoToggleEnabled(bool enabled) async {
    await _dao.setSetting(keyDndAutoToggle, enabled.toString());
  }

  /// Whether distracting app monitoring/blocking is enabled during Deep Work.
  Future<bool> isAppBlockingEnabled() async {
    final val = await _dao.getSetting(keyAppBlockingEnabled);
    return val == 'true';
  }

  Future<void> setAppBlockingEnabled(bool enabled) async {
    await _dao.setSetting(keyAppBlockingEnabled, enabled.toString());
  }

  /// List of package names to monitor/block during Deep Work.
  Future<List<String>> getBlockedAppPackages() async {
    final val = await _dao.getSetting(keyBlockedAppPackages);
    if (val != null) {
      try {
        final decoded = jsonDecode(val) as List;
        return List<String>.from(decoded);
      } catch (_) {}
    }
    return defaultBlockedPackages;
  }

  Future<void> setBlockedAppPackages(List<String> packages) async {
    await _dao.setSetting(keyBlockedAppPackages, jsonEncode(packages));
  }
}
