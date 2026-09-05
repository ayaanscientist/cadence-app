import 'package:flutter/material.dart';

class ConsistencyHeatmapWidget extends StatelessWidget {

  const ConsistencyHeatmapWidget({
    super.key,
    required this.heatmapData,
  });
  /// Map of Day Index (0-29, 0 being 30 days ago, 29 being today) to Intensity (0-4)
  final Map<int, int> heatmapData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '30-DAY CONSISTENCY',
            style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildGrid(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    // 30 days usually represented as 4-5 weeks of 7 days
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 30, // 30 days
      itemBuilder: (context, index) {
        final intensity = heatmapData[index] ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: _getColorForIntensity(intensity),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Less', style: TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(width: 4),
        _buildLegendBox(0),
        _buildLegendBox(1),
        _buildLegendBox(2),
        _buildLegendBox(3),
        _buildLegendBox(4),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildLegendBox(int intensity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForIntensity(int intensity) {
    switch (intensity) {
      case 1:
        return const Color(0xFF0E4429); // Light emerald
      case 2:
        return const Color(0xFF006D32); // Medium emerald
      case 3:
        return const Color(0xFF26A641); // Bright emerald
      case 4:
        return const Color(0xFF39D353); // Max emerald
      case 0:
      default:
        return const Color(0xFF2D2D2D); // Empty cell
    }
  }
}
