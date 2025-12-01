// Kylos IPTV Player - Live TV Categories Screen Tests
// Widget tests for the Live TV categories screen and category card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_category_card.dart';

void main() {
  group('LiveTvCategoryCard', () {
    testWidgets('displays category name', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test Category',
        channelCount: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Category'), findsOneWidget);
    });

    testWidgets('displays channel count', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('formats large channel counts with K suffix', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 1500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1.5K'), findsOneWidget);
    });

    testWidgets('displays play icon', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('displays chevron arrow', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LiveTvCategoryCard));
      expect(tapped, isTrue);
    });

    testWidgets('can receive autofocus', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Focus widget within LiveTvCategoryCard that has autofocus
      final focusFinder = find.descendant(
        of: find.byType(LiveTvCategoryCard),
        matching: find.byType(Focus),
      );
      final focus = tester.widget<Focus>(focusFinder.first);
      expect(focus.autofocus, isTrue);
    });

    testWidgets('renders with zero channel count', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'Empty Category',
        channelCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Empty Category'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders category with long name', (tester) async {
      const category = ChannelCategory(
        id: 'test',
        name: 'This is a very long category name that should be truncated',
        channelCount: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: LiveTvCategoryCard(
                category: category,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Should render without overflow
      expect(find.byType(LiveTvCategoryCard), findsOneWidget);
    });
  });

  group('ChannelCategory Entity', () {
    test('creates category with required fields', () {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test Category',
      );

      expect(category.id, 'test');
      expect(category.name, 'Test Category');
      expect(category.channelCount, 0);
      expect(category.isFavorite, false);
    });

    test('creates category with optional fields', () {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test Category',
        channelCount: 50,
        isFavorite: true,
        sortOrder: 5,
      );

      expect(category.channelCount, 50);
      expect(category.isFavorite, true);
      expect(category.sortOrder, 5);
    });

    test('copyWith creates new instance with updated values', () {
      const original = ChannelCategory(
        id: 'test',
        name: 'Original',
        channelCount: 10,
      );

      final updated = original.copyWith(
        name: 'Updated',
        channelCount: 20,
      );

      expect(updated.id, 'test');
      expect(updated.name, 'Updated');
      expect(updated.channelCount, 20);
    });

    test('copyWith preserves unspecified values', () {
      const original = ChannelCategory(
        id: 'test',
        name: 'Test',
        channelCount: 10,
        isFavorite: true,
        sortOrder: 5,
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.id, 'test');
      expect(updated.name, 'Updated');
      expect(updated.channelCount, 10);
      expect(updated.isFavorite, true);
      expect(updated.sortOrder, 5);
    });

    test('category with type defaults to live', () {
      const category = ChannelCategory(
        id: 'test',
        name: 'Test',
      );

      expect(category.type, CategoryType.live);
    });

    test('category can have different types', () {
      const vodCategory = ChannelCategory(
        id: 'test',
        name: 'Test',
        type: CategoryType.vod,
      );

      const seriesCategory = ChannelCategory(
        id: 'test2',
        name: 'Test 2',
        type: CategoryType.series,
      );

      expect(vodCategory.type, CategoryType.vod);
      expect(seriesCategory.type, CategoryType.series);
    });
  });
}
