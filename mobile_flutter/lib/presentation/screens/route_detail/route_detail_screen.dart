import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/data/models/stop_model.dart';
import 'package:mobile_flutter/providers/route_providers.dart';
import 'package:mobile_flutter/presentation/widgets/osm_map_widget.dart';
import 'package:mobile_flutter/presentation/widgets/simulated_badge.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  final int routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeDetailAsync = ref.watch(routeDetailProvider(widget.routeId));
    final routeStopsAsync = ref.watch(routeStopsProvider(widget.routeId));
    final scheduleAsync = ref.watch(routeScheduleProvider(widget.routeId));
    final busesAsync = ref.watch(routeBusesProvider(widget.routeId));
    final favourites = ref.watch(favouritesProvider);
    final isFav = favourites.contains(widget.routeId.toString());

    return routeDetailAsync.when(
      data: (route) {
        if (route == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Detail')),
            body: const EmptyStateView(
              title: 'Route Not Found',
              message: 'This route could not be found in the TMT database.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Route ${route.routeNumber}'),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? AppColors.accentAmber : Colors.white,
                ),
                tooltip: isFav ? 'Remove favourite' : 'Save route',
                onPressed: () {
                  ref.read(favouritesProvider.notifier).toggleFavourite(route.id.toString());
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share route',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('TMT Bus Route ${route.routeNumber}: ${route.source} → ${route.destination}')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Route Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BUS ${route.routeNumber}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (route.direction.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              route.direction.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        const Text(
                          'TMT Bus Service',
                          style: TextStyle(color: AppColors.accentTealLight, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${route.source} ➔ ${route.destination}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive OSM Map of Route Stops
              routeStopsAsync.when(
                data: (stops) {
                  return busesAsync.when(
                    data: (buses) => OsmMapWidget(
                      routeStops: stops,
                      buses: buses,
                      height: 200,
                      onStopSelected: (stop) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Stop: ${stop.name}')),
                        );
                      },
                    ),
                    loading: () => OsmMapWidget(routeStops: stops, height: 200),
                    error: (_, __) => OsmMapWidget(routeStops: stops, height: 200),
                  );
                },
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Map preview unavailable')),
                ),
              ),

              // TabBar: Stop Sequence / Schedules / Live Bus
              Container(
                color: AppColors.surfaceLight,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryNavy,
                  unselectedLabelColor: AppColors.textSecondaryLight,
                  indicatorColor: AppColors.accentTeal,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Stop Sequence'),
                    Tab(text: 'Timetable'),
                    Tab(text: 'Live Tracker'),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Stop Sequence Timeline
                    routeStopsAsync.when(
                      data: (stops) {
                        if (stops.isEmpty) {
                          return const EmptyStateView(
                            title: 'No Stops in Feed',
                            message: 'Stop sequence data for this route was not included in the supplied GTFS feed.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: stops.length,
                          itemBuilder: (context, index) {
                            final stop = stops[index];
                            final isFirst = index == 0;
                            final isLast = index == stops.length - 1;

                            return _StopTimelineItem(
                              stop: stop,
                              index: index + 1,
                              isFirst: isFirst,
                              isLast: isLast,
                            );
                          },
                        );
                      },
                      loading: () => const LoadingView(message: 'Loading ordered stop sequence...'),
                      error: (err, _) => ErrorStateView(message: err.toString()),
                    ),

                    // Tab 2: Timetable Departures
                    scheduleAsync.when(
                      data: (schedules) {
                        if (schedules.isEmpty) {
                          return const EmptyStateView(
                            icon: Icons.calendar_today_outlined,
                            title: 'Timetable Unavailable',
                            message: 'No GTFS departure schedule times found for this route in the active database.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: schedules.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = schedules[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.infoLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.schedule_rounded, size: 20, color: AppColors.accentTeal),
                              ),
                              title: Text(
                                item.departureTime,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'Scheduled departure from ${route.source}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevatedLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Trip #${item.tripIndex + 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingView(message: 'Loading timetable...'),
                      error: (err, _) => ErrorStateView(message: err.toString()),
                    ),

                    // Tab 3: Live Bus Tracker
                    busesAsync.when(
                      data: (buses) {
                        if (buses.isEmpty) {
                          return EmptyStateView(
                            icon: Icons.directions_bus_outlined,
                            title: 'No Active Tracking Vehicle',
                            message: 'No simulated active buses are currently running on Route ${route.routeNumber}. Try another major route like 54, AC-65 or 10.',
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Live Telemetry Status',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                                Spacer(),
                                SimulatedBadge(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...buses.map((bus) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              bus.vehicleNumber,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                            ),
                                            Text(
                                              'ETA ${bus.etaMinutes} mins',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentTeal),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Current stop: ${bus.currentStopName}', style: const TextStyle(fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('Approaching: ${bus.nextStopName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 8),
                                        Text('Simulated Speed: ~${bus.speed.round()} km/h · Heading: ${bus.heading.round()}°',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        );
                      },
                      loading: () => const LoadingView(message: 'Checking active buses...'),
                      error: (err, _) => ErrorStateView(message: err.toString()),
                    ),
                  ],
                ),
              ),

              // Bottom Booking Action Bar
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: const Border(top: BorderSide(color: AppColors.borderLight)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Estimated Fare', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            Text(
                              'From ₹10 · TMT AC/Regular',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/book/${route.id}'),
                        icon: const Icon(Icons.confirmation_num_rounded, size: 18),
                        label: const Text('Book Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Route Detail')),
        body: const LoadingView(message: 'Loading route details...'),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Route Detail')),
        body: ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(routeDetailProvider(widget.routeId)),
        ),
      ),
    );
  }
}

class _StopTimelineItem extends StatelessWidget {
  final StopModel stop;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _StopTimelineItem({
    required this.stop,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : AppColors.borderLight,
                  ),
                ),
                Container(
                  width: isFirst || isLast ? 18 : 12,
                  height: isFirst || isLast ? 18 : 12,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? AppColors.success
                        : isLast
                            ? AppColors.danger
                            : AppColors.accentTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.borderLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stop details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isFirst || isLast ? FontWeight.w800 : FontWeight.w600,
                      color: isFirst || isLast ? AppColors.primaryNavy : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (stop.departureTime != null && stop.departureTime!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Departure: ${stop.departureTime}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#$index',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
