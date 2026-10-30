import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/booking/booking_flow_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/nearby/nearby_screen.dart';
import '../../presentation/screens/notices/service_notices_screen.dart';
import '../../presentation/screens/planner/planner_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/route_detail/route_detail_screen.dart';
import '../../presentation/screens/routes/routes_screen.dart';
import '../../presentation/screens/shell/shell_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/tickets/ticket_detail_screen.dart';
import '../../presentation/screens/tickets/tickets_screen.dart';
import '../../presentation/screens/tracking/live_tracking_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Stateful Nested Shell Route for persistent bottom bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1: Plan Journey
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/planner',
              builder: (context, state) {
                final from = state.uri.queryParameters['from'] ?? '';
                final to = state.uri.queryParameters['to'] ?? '';
                return PlannerScreen(initialFrom: from, initialTo: to);
              },
            ),
          ],
        ),

        // Branch 2: Nearby
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nearby',
              builder: (context, state) => const NearbyScreen(),
            ),
          ],
        ),

        // Branch 3: My Tickets
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tickets',
              builder: (context, state) => const TicketsScreen(),
            ),
          ],
        ),

        // Branch 4: Profile & Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Push routes (outside bottom bar)
    GoRoute(
      path: '/routes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final query = state.uri.queryParameters['query'] ?? '';
        return RoutesScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/route/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return RouteDetailScreen(routeId: id);
      },
    ),
    GoRoute(
      path: '/tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LiveTrackingScreen(),
    ),
    GoRoute(
      path: '/book/:routeId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final routeId = int.tryParse(state.pathParameters['routeId'] ?? '') ?? 0;
        return BookingFlowScreen(routeId: routeId);
      },
    ),
    GoRoute(
      path: '/ticket/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final ticketId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TicketDetailScreen(ticketId: ticketId);
      },
    ),
    GoRoute(
      path: '/notices',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ServiceNoticesScreen(),
    ),
  ],
);
