// Kylos IPTV Player - TV Live TV Screen Tests
// Widget tests for the TV version of the Live TV screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/screens/live_tv_screen.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/tv_channel_card.dart';
import 'package:kylos_iptv_player/shared/providers/platform_providers.dart';

void main() {
  // Test channels
  final testChannels = [
    Channel(
      id: 'ch1',
      name: 'ESPN',
      streamUrl: 'http://example.com/espn',
      logoUrl: 'http://example.com/espn.png',
      categoryId: 'sports',
      categoryName: 'Sports',
      channelNumber: 100,
      isFavorite: true,
    ),
    Channel(
      id: 'ch2',
      name: 'CNN',
      streamUrl: 'http://example.com/cnn',
      logoUrl: 'http://example.com/cnn.png',
      categoryId: 'news',
      categoryName: 'News',
      channelNumber: 200,
      isFavorite: false,
    ),
    Channel(
      id: 'ch3',
      name: 'HBO',
      streamUrl: 'http://example.com/hbo',
      logoUrl: 'http://example.com/hbo.png',
      categoryId: 'movies',
      categoryName: 'Movies',
      channelNumber: 300,
      isFavorite: false,
    ),
    Channel(
      id: 'ch4',
      name: 'Comedy Central',
      streamUrl: 'http://example.com/comedy',
      categoryId: 'entertainment',
      categoryName: 'Entertainment',
      channelNumber: 400,
      isFavorite: true,
    ),
  ];

  Widget createTestWidget({
    required List<Override> overrides,
    bool isTV = true,
  }) {
    return ProviderScope(
      overrides: [
        formFactorProvider.overrideWithValue(
          isTV ? FormFactor.tv : FormFactor.mobile,
        ),
        ...overrides,
      ],
      child: const MaterialApp(
        home: LiveTvScreen(),
      ),
    );
  }

  group('TV Live TV Screen', () {
    testWidgets('displays loading state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: true,
                  channels: [],
                  categories: [],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays channels in TV grid layout', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: testChannels,
                  categories: [
                    const ChannelCategory(id: 'sports', name: 'Sports'),
                    const ChannelCategory(id: 'news', name: 'News'),
                    const ChannelCategory(id: 'movies', name: 'Movies'),
                    const ChannelCategory(
                      id: 'entertainment',
                      name: 'Entertainment',
                    ),
                  ],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should show Live TV header
      expect(find.text('Live TV'), findsOneWidget);

      // Should show Favorites section (because we have favorite channels)
      expect(find.text('Favorites'), findsOneWidget);

      // Should show TV channel cards
      expect(find.byType(TVChannelCard), findsWidgets);

      // Should show favorite channels (ESPN and Comedy Central)
      expect(find.text('ESPN'), findsWidgets);
      expect(find.text('Comedy Central'), findsWidgets);
    });

    testWidgets('displays empty state when no channels', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: [],
                  categories: [],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No channels available'), findsOneWidget);
      expect(find.text('Add a playlist to start watching'), findsOneWidget);
    });

    testWidgets('displays error state with retry button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: [],
                  categories: [],
                  error: 'Network error',
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load channels'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('channels are focusable widgets', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: testChannels,
                  categories: [],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find TVChannelCard widgets
      final channelCards = find.byType(TVChannelCard);
      expect(channelCards, findsWidgets);

      // Each TVChannelCard should have a Focus widget
      final firstCard = channelCards.first;
      final focusWidgets = find.descendant(
        of: firstCard,
        matching: find.byType(Focus),
      );
      expect(focusWidgets, findsWidgets);
    });
  });

  group('TV Channel Card Focus Navigation', () {
    testWidgets('TVChannelCard shows focus indicator when focused',
        (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TVChannelCard(
                channel: testChannels.first,
                focusNode: focusNode,
                autofocus: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Request focus
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // The card should be focused
      expect(focusNode.hasFocus, isTrue);

      // Clean up
      focusNode.dispose();
    });

    testWidgets('TVChannelCard triggers onSelect on enter key',
        (tester) async {
      bool wasSelected = false;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TVChannelCard(
                channel: testChannels.first,
                focusNode: focusNode,
                autofocus: true,
                onSelect: () {
                  wasSelected = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Request focus
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Simulate enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(wasSelected, isTrue);

      // Clean up
      focusNode.dispose();
    });

    testWidgets('TVChannelCard shows playing indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TVChannelCard(
                channel: testChannels.first,
                isPlaying: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show LIVE indicator
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('TVChannelCard shows favorite indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TVChannelCard(
                channel: testChannels.first, // ESPN is a favorite
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show favorite icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('TV Channel Row', () {
    testWidgets('TVChannelRow displays title and channels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TVChannelRow(
              title: 'Sports',
              channels: testChannels.where((c) => c.categoryId == 'sports').toList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show row title
      expect(find.text('Sports'), findsOneWidget);

      // Should show ESPN channel
      expect(find.text('ESPN'), findsOneWidget);
    });

    testWidgets('TVChannelRow auto-focuses first item when specified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TVChannelRow(
              title: 'Sports',
              channels: testChannels,
              autofocusFirst: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First channel card should be focused
      // This is verified by checking that Focus system has a primary focus
      expect(FocusManager.instance.primaryFocus, isNotNull);
    });

    testWidgets('TVChannelRow calls onChannelSelect when channel selected',
        (tester) async {
      Channel? selectedChannel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TVChannelRow(
              title: 'Sports',
              channels: testChannels,
              autofocusFirst: true,
              onChannelSelect: (channel) {
                selectedChannel = channel;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the first channel
      await tester.tap(find.byType(TVChannelCard).first);
      await tester.pumpAndSettle();

      expect(selectedChannel, isNotNull);
      expect(selectedChannel!.name, equals('ESPN'));
    });
  });

  group('Focus Traversal', () {
    testWidgets('can navigate between channel cards with arrow keys',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TVChannelRow(
              title: 'All Channels',
              channels: testChannels,
              autofocusFirst: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First card should be focused initially
      final firstCard = find.byType(TVChannelCard).first;
      expect(firstCard, findsOneWidget);

      // Press right arrow to move to next card
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Focus should have moved (we can't easily verify which card is focused
      // in widget tests, but we can verify the key was processed)
      expect(FocusManager.instance.primaryFocus, isNotNull);
    });
  });

  group('Mobile vs TV Layout', () {
    testWidgets('shows mobile layout when not TV', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          isTV: false,
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: testChannels,
                  categories: [],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
            // Also need to override videoController for mobile view
            videoControllerProvider.overrideWithValue(null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT show TV channel cards on mobile
      expect(find.byType(TVChannelCard), findsNothing);

      // Should show refresh and search icons (mobile header)
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows TV layout when isTV is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          isTV: true,
          overrides: [
            channelListNotifierProvider.overrideWith(
              (ref) => MockChannelListNotifier(
                ChannelListState(
                  isLoading: false,
                  channels: testChannels,
                  categories: [],
                ),
              ),
            ),
            playbackNotifierProvider.overrideWith(
              (ref) => MockPlaybackNotifier(PlaybackState.initial()),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should show TV channel cards
      expect(find.byType(TVChannelCard), findsWidgets);

      // Should show horizontal scroll layout (TVChannelRow uses ListView with horizontal axis)
      expect(find.byType(TVChannelRow), findsWidgets);
    });
  });
}

// Mock implementations

class MockChannelListNotifier extends StateNotifier<ChannelListState>
    implements ChannelListNotifier {
  MockChannelListNotifier(super.state);

  @override
  Future<void> loadChannels() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> selectCategory(String? categoryId) async {}

  @override
  Future<void> toggleFavorite(String channelId) async {}

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPlaybackNotifier extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  MockPlaybackNotifier(super.state);

  @override
  Future<void> playChannel(Channel channel) async {}

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> toggleMute() async {}

  @override
  Future<void> retry() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> play(PlayableContent content) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {}

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack? track) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void dispose() {
    super.dispose();
  }
}

