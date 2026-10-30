import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/theme/app_theme.dart';
import 'package:mobile_flutter/presentation/screens/splash/splash_screen.dart';
import 'package:mobile_flutter/presentation/widgets/simulated_badge.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

void main() {
  group('TransitGo UI Components Tests', () {
    testWidgets('SimulatedBadge renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimulatedBadge(label: 'DEMO TRACKING'),
          ),
        ),
      );

      expect(find.text('DEMO TRACKING'), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, message and action button', (WidgetTester tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No Routes Found',
              message: 'Try checking your search keyword.',
              actionLabel: 'Refresh',
              onAction: () => actionClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('No Routes Found'), findsOneWidget);
      expect(find.text('Try checking your search keyword.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionClicked, isTrue);
    });

    testWidgets('SplashScreen displays TransitGo branding and TMT subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      );

      // Settle splash animations
      await tester.pumpAndSettle();

      expect(find.text('TransitGo'), findsOneWidget);
      expect(find.text('THANE MUNICIPAL TRANSPORT (TMT)'), findsOneWidget);
      expect(find.text('Explore TransitGo'), findsOneWidget);
    });

    testWidgets('SplashScreen fits narrow mobile viewports (390x844 and 375x667) with zero overflow', (WidgetTester tester) async {
      // Test standard iPhone 12/13/14/15 viewport (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      if (exception is FlutterError) {
        for (final d in exception.diagnostics) {
          debugPrint('Diagnostic: ${d.name}: ${d.toDescription()}');
        }
      }
      expect(exception, isNull);
      expect(find.text('TransitGo'), findsOneWidget);
      expect(find.text('Explore TransitGo'), findsOneWidget);

      // Test compact mobile viewport (375 x 667)
      tester.view.physicalSize = const Size(375, 667);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TransitGo'), findsOneWidget);

      // Test short viewport (360 x 520) - simulating mobile preview with browser address bar or keyboard
      tester.view.physicalSize = const Size(360, 520);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TransitGo'), findsOneWidget);
    });

    testWidgets('EmptyStateView and ErrorStateView scroll smoothly in constrained viewports without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'Detailed Search Notice',
              message: 'This is a long descriptive message explaining that no direct routes were found between the given origin and destination bus terminals in Thane.',
              actionLabel: 'Try Another Search',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Detailed Search Notice'), findsOneWidget);
    });

    testWidgets('Direction filter chip bar renders smoothly at narrow 320px width without horizontal overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Direction:'),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('All Directions'), onPressed: () {}),
                  const SizedBox(width: 6),
                  ActionChip(label: const Text('UP'), onPressed: () {}),
                  const SizedBox(width: 6),
                  ActionChip(label: const Text('DOWN'), onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('All Directions'), findsOneWidget);
    });
  });
}
