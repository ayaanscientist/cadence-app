import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FrictionScreen extends StatefulWidget {
  const FrictionScreen({super.key});

  @override
  State<FrictionScreen> createState() => _FrictionScreenState();
}

class _FrictionScreenState extends State<FrictionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 5 second inhale/exhale animation cycle
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2, milliseconds: 500),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _countdown = 0;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _hardBlock() {
    // Send user back to Android Home Screen natively
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent physical back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, color: Colors.redAccent, size: 48),
                const SizedBox(height: 30),
                const Text(
                  'DEEP WORK SHIELD ACTIVE',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    return Container(
                      width: 100 + (_breathController.value * 100),
                      height: 100 + (_breathController.value * 100),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _countdown > 0 ? '$_countdown' : 'Breathe',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 60),
                const Text(
                  'Is opening this app strictly necessary right now?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                if (_countdown == 0)
                  Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 60),
                        ),
                        onPressed: _hardBlock,
                        child: const Text('NO, RETURN TO FOCUS', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Yes, it is necessary', style: TextStyle(color: Colors.grey)),
                      )
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
