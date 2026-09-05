import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cadence/features/physical/logic/biometric_calculator.dart';

class EnergyRhythmCurveWidget extends StatelessWidget {

  const EnergyRhythmCurveWidget({
    super.key,
    required this.rollingSleepDebtHours,
    required this.wakeTime,
  });
  final double rollingSleepDebtHours;
  final TimeOfDay wakeTime;

  @override
  Widget build(BuildContext context) {
    // Assess sleep debt to determine colors and curve severity
    final assessment = BiometricCalculator.assessSleepDebt(rollingSleepDebtHours);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CIRCADIAN ENERGY RHYTHM', style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            assessment.title,
            style: TextStyle(color: Color(assessment.colorHex), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _EnergyCurvePainter(
                sleepDebt: rollingSleepDebtHours,
                wakeHour: wakeTime.hour + (wakeTime.minute / 60.0),
                themeColor: Color(assessment.colorHex),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('12 PM', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('6 PM', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('12 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class _EnergyCurvePainter extends CustomPainter {

  _EnergyCurvePainter({
    required this.sleepDebt,
    required this.wakeHour,
    required this.themeColor,
  });
  final double sleepDebt;
  final double wakeHour;
  final Color themeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withValues(alpha: 0.4),
          themeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Calculate the dip severity based on sleep debt (max debt = deeper dip)
    // Baseline dip is around 2-4 PM (hour 14-16)
    final dipSeverity = 1.0 + (sleepDebt / 4.0).clamp(0.0, 2.0); 

    // Draw the curve for 24 hours (6 AM to 6 AM for visual alignment)
    for (int i = 0; i <= size.width; i++) {
      final t = i / size.width; // 0.0 to 1.0 representing the 24h cycle
      final currentHour = 6.0 + (t * 24.0); // Maps x to hours
      
      // Biorhythm approximation (two peaks, one dip)
      // Peak 1: Wake time + 4 hours (e.g. 10 AM)
      // Peak 2: Wake time + 12 hours (e.g. 6 PM)
      // Dip: Wake time + 8 hours (e.g. 2 PM)
      
      final offsetFromWake = currentHour - wakeHour;
      
      // Simple sine composition to simulate the circadian rhythm
      double yValue = sin(offsetFromWake * pi / 12) + 0.5 * sin(offsetFromWake * pi / 6);
      
      // Apply sleep debt severity to the afternoon dip (approx offset 8)
      if (offsetFromWake > 6 && offsetFromWake < 10) {
        yValue -= dipSeverity * 0.3 * sin((offsetFromWake - 6) * pi / 4);
      }

      // Normalize and scale to canvas
      // Invert Y axis for canvas drawing (0 is top)
      final normalizedY = (yValue / 2.5).clamp(-1.0, 1.0); 
      final y = (size.height / 2) - (normalizedY * (size.height / 2));

      if (i == 0) {
        path.moveTo(i.toDouble(), y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }

    // Draw the curve line
    canvas.drawPath(path, paint);

    // Draw the gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw baseline
    final baseline = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
      
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), baseline);
  }

  @override
  bool shouldRepaint(covariant _EnergyCurvePainter oldDelegate) {
    return oldDelegate.sleepDebt != sleepDebt || 
           oldDelegate.wakeHour != wakeHour ||
           oldDelegate.themeColor != themeColor;
  }
}
