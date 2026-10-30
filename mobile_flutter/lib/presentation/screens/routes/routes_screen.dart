import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/route_providers.dart';
import 'package:mobile_flutter/presentation/widgets/route_card.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class RoutesScreen extends ConsumerStatefulWidget {
  final String initialQuery;

  const RoutesScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  late final TextEditingController _searchController;
  String _selectedDirection = 'ALL'; // ALL, UP, DOWN

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TMT Bus Routes'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by route number, source or destination...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.accentTeal),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Direction:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'All Directions',
                        isSelected: _selectedDirection == 'ALL',
                        onSelected: () => setState(() => _selectedDirection = 'ALL'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'UP',
                        isSelected: _selectedDirection == 'UP',
                        onSelected: () => setState(() => _selectedDirection = 'UP'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'DOWN',
                        isSelected: _selectedDirection == 'DOWN',
                        onSelected: () => setState(() => _selectedDirection = 'DOWN'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Routes List
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                final query = _searchController.text.trim().toLowerCase();

                final filtered = routes.filter((r) {
                  // Direction check
                  if (_selectedDirection != 'ALL' &&
                      !r.direction.equalsIgnoreCase(_selectedDirection)) {
                    return false;
                  }
                  if (query.isEmpty) return true;

                  // Text match on route number, source, destination, or route name
                  final numMatch = r.routeNumber.toLowerCase().contains(query);
                  final srcMatch = r.source.toLowerCase().contains(query);
                  final dstMatch = r.destination.toLowerCase().contains(query);
                  final nameMatch = r.routeName.toLowerCase().contains(query);

                  return numMatch || srcMatch || dstMatch || nameMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Routes',
                    message: 'No TMT routes found matching "$query". Check route number or search by terminal location.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Showing ${filtered.length} of ${routes.length} verified TMT routes',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }

                    final route = filtered[index - 1];
                    return RouteCard(
                      route: route,
                      onTap: () => context.push('/route/${route.id}'),
                      onBookTap: () => context.push('/book/${route.id}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(message: 'Loading 436 verified TMT routes...'),
              error: (err, _) => ErrorStateView(
                message: err.toString(),
                onRetry: () => ref.invalidate(routesListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
      ),
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.surfaceElevatedLight,
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
      ),
    );
  }
}

extension _StringExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T element) test) => where(test);
}
