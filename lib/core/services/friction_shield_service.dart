import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cadence/core/services/focus_control_service.dart';
import 'package:cadence/features/founder/ui/friction_screen.dart';

class FrictionShieldService {
  FrictionShieldService._();
  static final FrictionShieldService instance = FrictionShieldService._();

  Timer? _pollingTimer;
  bool _isShieldActive = false;
  
  // Example blocklist
  final List<String> _blockedPackages = [
    'com.instagram.android',
    'com.google.android.youtube',
    'com.twitter.android',
    'com.zhiliaoapp.musically', // TikTok
  ];

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void startDeepWorkShield() {
    if (_isShieldActive) return;
    _isShieldActive = true;
    
    // Poll every 2 seconds to check foreground app
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final isBlocked = await FocusControlService.instance.isForegroundAppBlocked(_blockedPackages);
      
      if (isBlocked) {
        _triggerFrictionScreen();
      }
    });
  }

  void stopDeepWorkShield() {
    _isShieldActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _triggerFrictionScreen() {
    // We assume the app is brought to foreground natively, 
    // or this triggers inside our own Flutter overlay context.
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Prevent multiple overlays
      if (ModalRoute.of(context)?.settings.name != '/friction') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FrictionScreen(),
            settings: const RouteSettings(name: '/friction'),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }
}
