import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/data/models/stop_model.dart';
import 'package:mobile_flutter/providers/location_provider.dart';
import 'package:mobile_flutter/providers/stop_providers.dart';
import 'package:mobile_flutter/presentation/widgets/osm_map_widget.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';
import 'package:mobile_flutter/presentation/widgets/stop_card.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStopTapped(StopModel stop) {
    _showStopBottomSheet(stop);
  }

  void _showStopBottomSheet(StopModel stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final stopDetailAsync = ref.watch(stopDetailProvider(stop.id));

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: AppColors.accentTeal),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            if (stop.distanceKm != null)
                              Text(
                                '${stop.distanceKm!.toStringAsFixed(1)} km away',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Routes Serving This Stop:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  stopDetailAsync.when(
                    data: (detail) {
                      final routes = detail?.routes ?? [];
                      if (routes.isEmpty) {
                        return const Text(
                          'No active route mapping available.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: routes.take(6).map((r) {
                          return ActionChip(
                            avatar: const Icon(Icons.directions_bus, size: 14, color: AppColors.accentAmber),
                            label: Text('BUS ${r.routeNumber}'),
                            backgroundColor: AppColors.primaryNavy,
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/route/${r.id}');
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Could not load serving routes'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/planner?from=${Uri.encodeComponent(stop.name)}');
                      },
                      icon: const Icon(Icons.route_rounded, size: 18),
                      label: const Text('Plan Journey From Here'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final nearbyAsync = ref.watch(nearbyStopsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Nearby Bus Stops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Update Location',
            onPressed: () {
              ref.read(locationProvider.notifier).requestLocation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search stop bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Filter nearby stops by name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accentTeal),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // OSM Map with Nearby Stops
          nearbyAsync.when(
            data: (stops) {
              return OsmMapWidget(
                height: 200,
                userLocation: LatLng(location.latitude, location.longitude),
                routeStops: stops.take(20).toList(),
                onStopSelected: _onStopTapped,
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: LoadingView(message: 'Loading map pins...'),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(child: Text('Map tile error')),
            ),
          ),

          // Status & List Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceElevatedLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded, size: 16, color: AppColors.accentTeal),
                    const SizedBox(width: 6),
                    Text(
                      location.isDefaultLocation
                          ? 'Hub: Thane Station (Default)'
                          : 'GPS: Current Location',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => ref.read(locationProvider.notifier).requestLocation(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Refresh GPS', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Nearby Stops List
          Expanded(
            child: nearbyAsync.when(
              data: (stops) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = stops.where((s) {
                  if (query.isEmpty) return true;
                  return s.name.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.location_off_rounded,
                    title: 'No Stops Found',
                    message: 'No stops found within 5 km. Try refreshing GPS or check your search keyword.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final stop = filtered[index];
                    return StopCard(
                      stop: stop,
                      onTap: () => _onStopTapped(stop),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        onPressed: () => _onStopTapped(stop),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(message: 'Finding nearest TMT stops...'),
              error: (err, _) => ErrorStateView(
                message: err.toString(),
                onRetry: () => ref.invalidate(nearbyStopsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
