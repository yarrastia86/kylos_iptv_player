// Kylos IPTV Player - Live TV Overflow Menu Tests
// Widget tests for the overflow menu and menu items.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_overflow_menu.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_overflow_menu_item.dart';

void main() {
  group('LiveTvOverflowMenuItem', () {
    testWidgets('displays icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenuItem(
              icon: Icons.home,
              label: 'Home',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenuItem(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LiveTvOverflowMenuItem));
      expect(tapped, isTrue);
    });

    testWidgets('can receive autofocus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenuItem(
              icon: Icons.home,
              label: 'Home',
              onTap: () {},
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final focusFinder = find.descendant(
        of: find.byType(LiveTvOverflowMenuItem),
        matching: find.byType(Focus),
      );
      final focus = tester.widget<Focus>(focusFinder.first);
      expect(focus.autofocus, isTrue);
    });

    testWidgets('shows chevron indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenuItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('LiveTvOverflowMenu', () {
    testWidgets('displays header with Menu title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('displays all standard menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all menu items are displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Refresh Channels, Movies and Series'), findsOneWidget);
      expect(find.text('Refresh TV Guide'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('displays correct icons for menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('calls onItemSelected when menu item tapped', (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (id) => selectedId = id,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Home menu item
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(selectedId, equals('home'));
    });

    testWidgets('calls onDismiss when tapping outside menu', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap outside the menu (on the backdrop)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('displays close button in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays menu icon in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvOverflowMenu(
              onItemSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Menu icon in header
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });

  group('OverflowMenuItem', () {
    test('creates menu item with correct values', () {
      const item = OverflowMenuItem(
        id: 'test',
        icon: Icons.star,
        label: 'Test Item',
      );

      expect(item.id, equals('test'));
      expect(item.icon, equals(Icons.star));
      expect(item.label, equals('Test Item'));
    });

    test('standardItems contains all required items', () {
      final items = LiveTvOverflowMenu.standardItems;

      expect(items.length, equals(6));
      expect(items.any((i) => i.id == 'home'), isTrue);
      expect(items.any((i) => i.id == 'refresh_content'), isTrue);
      expect(items.any((i) => i.id == 'refresh_epg'), isTrue);
      expect(items.any((i) => i.id == 'sort'), isTrue);
      expect(items.any((i) => i.id == 'settings'), isTrue);
      expect(items.any((i) => i.id == 'logout'), isTrue);
    });
  });
}
