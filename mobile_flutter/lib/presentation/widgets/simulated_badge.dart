import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SimulatedBadge extends StatelessWidget {
  final String label;
  final bool isCompact;

  const SimulatedBadge({
    super.key,
    this.label = 'SIMULATED DEMO',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.simulatedBadge),
                SizedBox(width: 8),
                Text('Simulated Tracking Mode', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: const Text(
              'This vehicle position and ETA are simulated using GTFS scheduled timetables and mock movement engines. Real-time GPS hardware feeds are not currently active.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.simulatedBadgeLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.simulatedBadge.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.simulatedBadge,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.simulatedBadge,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
