import 'package:flutter/material.dart';
import 'package:cadence/features/physical/logic/biometric_calculator.dart';

class EnergyBalanceWidget extends StatelessWidget {

  const EnergyBalanceWidget({
    super.key,
    required this.caloriesConsumed,
    required this.bmr,
    required this.activeEnergyBurned,
  });
  final int caloriesConsumed;
  final double bmr;
  final int activeEnergyBurned;

  @override
  Widget build(BuildContext context) {
    final totalOut = bmr.round() + activeEnergyBurned;
    final netEnergy = BiometricCalculator.calculateNetEnergyBalance(
      caloriesConsumed: caloriesConsumed,
      bmr: bmr,
      activeEnergyBurned: activeEnergyBurned,
    );
    
    // For progress bar scaling, assume max possible is around 4000
    const maxScale = 4000.0;
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ENERGY BALANCE', style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Text(
                '${netEnergy > 0 ? '+' : ''}$netEnergy kcal',
                style: TextStyle(
                  color: netEnergy > 0 ? Colors.blueAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBar('GAIN (IN)', caloriesConsumed, Colors.blueAccent, maxScale),
          const SizedBox(height: 15),
          _buildBar('LOSS (OUT)', totalOut, Colors.orangeAccent, maxScale),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Includes BMR + Active Burn', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('$activeEnergyBurned kcal active', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color, double maxScale) {
    final ratio = (value / maxScale).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('$value kcal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
