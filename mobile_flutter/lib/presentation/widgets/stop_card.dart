import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/stop_model.dart';

class StopCard extends StatelessWidget {
  final StopModel stop;
  final VoidCallback onTap;
  final Widget? trailing;

  const StopCard({
    super.key,
    required this.stop,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_on_rounded, color: AppColors.accentTeal, size: 22),
        ),
        title: Text(
          stop.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Row(
          children: [
            if (stop.distanceKm != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${stop.distanceKm!.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
            if (stop.sequence != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Stop #${stop.sequence}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ],
        ),
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMutedLight, size: 20),
      ),
    );
  }
}
