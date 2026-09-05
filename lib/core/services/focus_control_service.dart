import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Native service bridge for deep work focus control:
/// - Android Do Not Disturb (DND) mode manipulation via NotificationManager
/// - App usage statistics monitoring for distracting app boundary enforcement
class FocusControlService {
  FocusControlService._();
  static final FocusControlService instance = FocusControlService._();

  static const MethodChannel _channel =
      MethodChannel('com.atomicos.cadence/focus_control');

  // ── Do Not Disturb (DND) Control ──────────────────────────────────────

  /// Checks if the application has been granted permission to modify DND policy.
  Future<bool> isDndPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool granted =
          await _channel.invokeMethod('isDndPermissionGranted') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android system settings screen to request Notification Policy Access.
  Future<void> openDndPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openDndPermissionSettings');
    } catch (_) {}
  }

  /// Enables or disables Do Not Disturb mode.
  ///
  /// Requires `ACCESS_NOTIFICATION_POLICY` permission granted by the user.
  Future<bool> setDoNotDisturb(bool enable) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool success =
          await _channel.invokeMethod('setDoNotDisturb', {'enable': enable}) ??
              false;
      return success;
    } catch (_) {
      return false;
    }
  }

  // ── Usage Stats & Distraction App Monitoring ──────────────────────────

  /// Checks if the user has granted Usage Access permission (`PACKAGE_USAGE_STATS`).
  Future<bool> isUsageStatsPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool granted =
          await _channel.invokeMethod('isUsageStatsPermissionGranted') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android Usage Access settings screen.
  Future<void> openUsageStatsPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageStatsPermissionSettings');
    } catch (_) {}
  }

  /// Returns the package name of the application currently in the foreground.
  Future<String?> getForegroundPackage() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? packageName =
          await _channel.invokeMethod('getForegroundPackage');
      return packageName;
    } catch (_) {
      return null;
    }
  }

  /// Checks if the currently active foreground app is in the designated blocked list.
  Future<bool> isForegroundAppBlocked(List<String> blockedPackages) async {
    if (!Platform.isAndroid) return false;
    final currentApp = await getForegroundPackage();
    if (currentApp == null) return false;
    return blockedPackages.contains(currentApp);
  }
}
