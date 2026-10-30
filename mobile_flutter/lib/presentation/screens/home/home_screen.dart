import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/location_provider.dart';
import 'package:mobile_flutter/providers/notice_providers.dart';
import 'package:mobile_flutter/providers/route_providers.dart';
import 'package:mobile_flutter/providers/stop_providers.dart';
import 'package:mobile_flutter/presentation/widgets/route_card.dart';
import 'package:mobile_flutter/presentation/widgets/stop_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _routeSearchController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _routeSearchController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
    setState(() {});
  }

  void _useCurrentLocation() {
    ref.read(locationProvider.notifier).requestLocation();
    _fromController.text = 'Current Location (Thane)';
    setState(() {});
  }

  void _onFindBuses() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty && to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an origin or destination')),
      );
      return;
    }
    ref.read(recentSearchesProvider.notifier).addSearch(from, to);
    context.push('/planner?from=${Uri.encodeComponent(from)}&to=${Uri.encodeComponent(to)}');
  }

  void _onSearchRouteNumber(String query) {
    if (query.trim().isEmpty) return;
    context.push('/routes?query=${Uri.encodeComponent(query.trim())}');
  }

  @override
  Widget build(BuildContext context) {
    final nearbyStopsAsync = ref.watch(nearbyStopsProvider);
    final allRoutesAsync = ref.watch(routesListProvider);
    final favourites = ref.watch(favouritesProvider);
    final recentSearches = ref.watch(recentSearchesProvider);
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // TransitGo Top App Bar with brand accent
          SliverAppBar(
            pinned: true,
            expandedHeight: 110.0,
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_bus, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TransitGo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Thane Municipal Transport',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentTealLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                tooltip: 'Service Alerts',
                onPressed: () => context.push('/notices'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verified Service Notice Alert (if available)
                  noticesAsync.when(
                    data: (notices) {
                      if (notices.isEmpty) return const SizedBox.shrink();
                      final notice = notices.first;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.campaign_rounded, color: AppColors.info, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                notice.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/notices'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Origin & Destination Journey Card
                  Card(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Where are you heading?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Icon(Icons.commute_rounded, color: AppColors.accentTeal, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Origin input
                          Row(
                            children: [
                              const Icon(Icons.trip_origin_rounded, size: 18, color: AppColors.success),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _fromController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter boarding stop / area',
                                    isDense: true,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.my_location, size: 18, color: AppColors.accentTeal),
                                      tooltip: 'Use current location',
                                      onPressed: _useCurrentLocation,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Vertical divider with Swap button
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                            child: Row(
                              children: [
                                Container(width: 2, height: 20, color: AppColors.borderLight),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.swap_vert_rounded, color: AppColors.accentTeal),
                                  onPressed: _swapLocations,
                                  tooltip: 'Swap locations',
                                ),
                              ],
                            ),
                          ),

                          // Destination input
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 18, color: AppColors.danger),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _toController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter destination stop',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Find Buses Action
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _onFindBuses,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Find Available Buses', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Route Number Lookup Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textMutedLight, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _routeSearchController,
                            onSubmitted: _onSearchRouteNumber,
                            decoration: const InputDecoration(
                              hintText: 'Search by route number (e.g. 54, AC-65)...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryNavy, size: 18),
                          onPressed: () => _onSearchRouteNumber(_routeSearchController.text),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Grid
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.map_rounded,
                          label: 'All Routes\n(436 TMT)',
                          color: AppColors.primaryNavy,
                          onTap: () => context.push('/routes'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.near_me_rounded,
                          label: 'Nearby\nStops',
                          color: AppColors.accentTeal,
                          onTap: () => context.push('/nearby'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.radar_rounded,
                          label: 'Live Bus\nTracking',
                          color: AppColors.accentAmber,
                          onTap: () => context.push('/tracking'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.confirmation_num_rounded,
                          label: 'Digital\nTickets',
                          color: AppColors.success,
                          onTap: () => context.push('/tickets'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Favourite Routes Section (if any saved)
                  if (favourites.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saved Routes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${favourites.length} saved',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    allRoutesAsync.when(
                      data: (routes) {
                        final favRoutes = routes
                            .where((r) => favourites.contains(r.id.toString()))
                            .take(4)
                            .toList();
                        return Column(
                          children: favRoutes.map((route) {
                            return RouteCard(
                              route: route,
                              onTap: () => context.push('/route/${route.id}'),
                              onBookTap: () => context.push('/book/${route.id}'),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recently Searched Journeys
                  if (recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Searches',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recentSearches.take(4).map((item) {
                        final label = '${item['from']} → ${item['to']}';
                        return ActionChip(
                          avatar: const Icon(Icons.history_rounded, size: 14),
                          label: Text(label.length > 28 ? '${label.substring(0, 26)}...' : label),
                          onPressed: () {
                            context.push(
                              '/planner?from=${Uri.encodeComponent(item['from'] ?? '')}&to=${Uri.encodeComponent(item['to'] ?? '')}',
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Nearby Bus Stops Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby TMT Bus Stops',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () => context.push('/nearby'),
                        child: const Text('View All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  nearbyStopsAsync.when(
                    data: (stops) {
                      if (stops.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No stops found in 5 km radius. Grant GPS permission to see closest stops.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                        );
                      }
                      return Column(
                        children: stops.take(4).map((stop) {
                          return StopCard(
                            stop: stop,
                            onTap: () {
                              _fromController.text = stop.name;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected "${stop.name}" as starting stop')),
                              );
                            },
                            trailing: TextButton(
                              child: const Text('From here', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                _fromController.text = stop.name;
                                _onFindBuses();
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Unable to load nearby stops: $err'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
