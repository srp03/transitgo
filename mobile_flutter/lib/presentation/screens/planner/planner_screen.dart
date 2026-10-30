import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/location_provider.dart';
import 'package:mobile_flutter/providers/route_providers.dart';
import 'package:mobile_flutter/presentation/widgets/route_card.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final String initialFrom;
  final String initialTo;

  const PlannerScreen({
    super.key,
    this.initialFrom = '',
    this.initialTo = '',
  });

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  SearchParams? _activeParams;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom);
    _toController = TextEditingController(text: widget.initialTo);

    if (widget.initialFrom.isNotEmpty || widget.initialTo.isNotEmpty) {
      _activeParams = SearchParams(from: widget.initialFrom, to: widget.initialTo);
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _search() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty && to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an origin or destination stop')),
      );
      return;
    }
    ref.read(recentSearchesProvider.notifier).addSearch(from, to);
    setState(() {
      _activeParams = SearchParams(from: from, to: to);
    });
  }

  void _swap() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
    _search();
  }

  void _useCurrentLocation() {
    ref.read(locationProvider.notifier).requestLocation();
    _fromController.text = 'Thane';
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = _activeParams != null
        ? ref.watch(routeSearchProvider(_activeParams!))
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Journey Planner'),
      ),
      body: Column(
        children: [
          // Input Header Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.trip_origin_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Boarding stop (e.g. Thane Station)',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location, size: 18, color: AppColors.accentTeal),
                            tooltip: 'Current location',
                            onPressed: _useCurrentLocation,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.swap_vert_rounded, color: AppColors.accentTeal),
                        tooltip: 'Swap locations',
                        onPressed: _swap,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          hintText: 'Destination stop (e.g. Borivali, Ghodbunder)',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.directions_bus_rounded, size: 18),
                    label: const Text('Find Journey Routes'),
                  ),
                ),
              ],
            ),
          ),

          // Search Results View
          Expanded(
            child: _activeParams == null
                ? const EmptyStateView(
                    icon: Icons.map_outlined,
                    title: 'Plan Your TMT Bus Ride',
                    message:
                        'Enter a boarding point and destination to find all verified direct and connected Thane Municipal Transport bus services.',
                  )
                : searchAsync!.when(
                    data: (routes) {
                      if (routes.isEmpty) {
                        return EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: 'No Direct Routes Found',
                          message:
                              'No direct TMT bus service found connecting "${_activeParams!.from}" and "${_activeParams!.to}". Try searching by terminal stop name or route number directly.',
                          actionLabel: 'Browse All 436 Routes',
                          onAction: () => context.push('/routes'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: routes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${routes.length} Direct Route${routes.length == 1 ? '' : 's'} Available',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Direct Service',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final route = routes[index - 1];
                          return RouteCard(
                            route: route,
                            onTap: () => context.push('/route/${route.id}'),
                            onBookTap: () => context.push('/book/${route.id}'),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingView(message: 'Searching TMT route network...'),
                    error: (err, _) => ErrorStateView(
                      message: err.toString(),
                      onRetry: _search,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
