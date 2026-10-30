import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/notice_providers.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class ServiceNoticesScreen extends ConsumerWidget {
  const ServiceNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Notices & Alerts'),
      ),
      body: noticesAsync.when(
        data: (notices) {
          if (notices.isEmpty) {
            return const EmptyStateView(
              icon: Icons.check_circle_outline_rounded,
              title: 'No Active Disruptions',
              message: 'All Thane Municipal Transport bus services are operating normally with no verified service alerts.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notice.category == 'HELPLINE'
                                  ? AppColors.infoLight
                                  : notice.category == 'EMERGENCY'
                                      ? AppColors.dangerLight
                                      : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notice.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: notice.category == 'HELPLINE'
                                    ? AppColors.info
                                    : notice.category == 'EMERGENCY'
                                        ? AppColors.danger
                                        : AppColors.warning,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.accentTeal),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentTeal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notice.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.description,
                        style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textPrimaryLight),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Source: ${notice.source}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          Text(
                            notice.publishedAt,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(message: 'Loading verified advisories...'),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(noticesProvider),
        ),
      ),
    );
  }
}
