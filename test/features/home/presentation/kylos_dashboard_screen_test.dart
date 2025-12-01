// Kylos IPTV Player - Dashboard Screen Tests
// Widget tests for the main dashboard screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/home/presentation/screens/kylos_dashboard_screen.dart';
import 'package:kylos_iptv_player/features/home/presentation/widgets/kylos_primary_tile.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';

void main() {
  group('KylosDashboardScreen', () {
    late ProviderContainer container;

    Widget buildTestWidget({PlaylistSource? activePlaylist}) {
      // Create container with overrides
      container = ProviderContainer(
        overrides: [
          activePlaylistProvider.overrideWithValue(activePlaylist),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: KylosDashboardScreen(),
        ),
      );
    }

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders main navigation tiles', (tester) async {
      // Set a larger surface size to accommodate bigger tiles
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create a mock active playlist
      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify all three main tiles are present
      expect(find.text('LIVE TV'), findsOneWidget);
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.text('SERIES'), findsOneWidget);
    });

    testWidgets('renders top bar with app name', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify app branding is present
      expect(find.text('KYLOS'), findsOneWidget);
      expect(find.text('IPTV PLAYER'), findsOneWidget);
    });

    testWidgets('renders KylosPrimaryTile widgets', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify KylosPrimaryTile widgets are rendered
      expect(find.byType(KylosPrimaryTile), findsNWidgets(3));
    });

    testWidgets('renders top bar action icons', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify action icons are present
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('renders dark gradient background', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify the container with gradient exists
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('tile icons are displayed correctly', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlaylist = PlaylistSource(
        id: 'test-playlist',
        name: 'Test Playlist',
        type: PlaylistType.m3uUrl,
      );

      await tester.pumpWidget(buildTestWidget(activePlaylist: mockPlaylist));
      await tester.pumpAndSettle();

      // Verify icons for main tiles
      expect(find.byIcon(Icons.live_tv), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });
  });
}
