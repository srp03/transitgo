import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/bus_providers.dart';
import 'package:mobile_flutter/presentation/widgets/bus_live_card.dart';
import 'package:mobile_flutter/presentation/widgets/osm_map_widget.dart';
import 'package:mobile_flutter/presentation/widgets/simulated_badge.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh simulated positions every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.invalidate(liveBusesProvider);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveBusesAsync = ref.watch(liveBusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Positions',
            onPressed: () => ref.invalidate(liveBusesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Prominent Demo / Simulated Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.simulatedBadgeLight,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.simulatedBadge),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Simulated Tracking Mode: Movement is generated from timetable schedules for demonstration.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.simulatedBadge,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SimulatedBadge(isCompact: true),
              ],
            ),
          ),

          // Map View with live bus markers
          liveBusesAsync.when(
            data: (buses) {
              return OsmMapWidget(
                height: 250,
                buses: buses,
                onBusSelected: (bus) {
                  context.push('/route/${bus.routeId}');
                },
              );
            },
            loading: () => const SizedBox(
              height: 250,
              child: LoadingView(message: 'Tracking active buses...'),
            ),
            error: (_, __) => const SizedBox(
              height: 250,
              child: Center(child: Text('Tracking feed unavailable')),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Tracked Vehicles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Live Feed (3s)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tracked Buses List
          Expanded(
            child: liveBusesAsync.when(
              data: (buses) {
                if (buses.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.directions_bus_outlined,
                    title: 'No Active Buses',
                    message: 'No simulated buses are currently reporting location coordinates in the backend.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    return BusLiveCard(
                      bus: bus,
                      onTap: () => context.push('/route/${bus.routeId}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(message: 'Loading telemetry positions...'),
              error: (err, _) => ErrorStateView(
                message: err.toString(),
                onRetry: () => ref.invalidate(liveBusesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
