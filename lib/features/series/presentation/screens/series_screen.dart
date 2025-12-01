// Kylos IPTV Player - Series Screen
// Screen for browsing TV series content.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_category.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/features/series/presentation/widgets/series_category_card.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// TV Series screen.
///
/// Displays available TV series from the user's playlists
/// organized by categories in a two-column layout.
class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seriesListNotifierProvider.notifier).loadCategories();
    });
  }

  void _navigateToCategoryList(SeriesCategory category) {
    context.push(
      Routes.seriesCategoryPath(category.id),
      extra: category.name,
    );
  }

  void _handleSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search - Coming Soon')),
    );
  }

  void _handleMore() {
    _showOptionsMenu();
  }

  void _showOptionsMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Options',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.refresh, color: KylosColors.textSecondary),
              title: const Text(
                'Refresh',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleRefresh();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.sort, color: KylosColors.textSecondary),
              title: const Text(
                'Sort',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sort - Coming Soon')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.settings, color: KylosColors.textSecondary),
              title: const Text(
                'Settings',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.settings);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: KylosColors.textSecondary),
              title: const Text(
                'Logout',
                style: TextStyle(color: KylosColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Refreshing series...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    await ref.read(seriesListNotifierProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Series refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Logout',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout? This will clear your active playlist.',
          style: TextStyle(color: KylosColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if ((shouldLogout ?? false) && mounted) {
      ref.read(activePlaylistNotifierProvider.notifier).clearActivePlaylist();
      context.go(Routes.onboarding);
    }
  }

  void _handleBack() {
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesListNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KylosColors.backgroundStart,
              KylosColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _buildContent(seriesState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.m,
        vertical: KylosSpacing.s,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: KylosColors.textPrimary),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          const Expanded(
            child: Center(
              child: Text(
                'SERIES',
                style: TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: KylosColors.textSecondary),
            onPressed: _handleSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: KylosColors.textSecondary),
            onPressed: _handleMore,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SeriesListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.seriesGlow,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: KylosColors.textMuted,
            ),
            const SizedBox(height: KylosSpacing.m),
            const Text(
              'Failed to load categories',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            Text(
              state.error!,
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KylosSpacing.l),
            FilledButton.icon(
              onPressed: () {
                ref.read(seriesListNotifierProvider.notifier).loadCategories();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.tv_off,
              size: 64,
              color: KylosColors.textMuted,
            ),
            SizedBox(height: KylosSpacing.m),
            Text(
              'No series available',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: KylosSpacing.xs),
            Text(
              'Add a playlist with series content',
              style: TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Build categories with ALL and FAVOURITES at top
    final categories = _buildCategoriesWithSpecial(state);

    return _buildCategoryList(categories);
  }

  List<SeriesCategory> _buildCategoriesWithSpecial(SeriesListState state) {
    final allCategory = SeriesCategory(
      id: 'all',
      name: 'ALL',
      seriesCount: state.allSeriesCount,
      sortOrder: -2,
    );

    final favoritesCategory = SeriesCategory(
      id: 'favorites',
      name: 'FAVORITES',
      seriesCount: state.favoritesCount,
      sortOrder: -1,
      isFavorite: true,
    );

    return [allCategory, favoritesCategory, ...state.categories];
  }

  Widget _buildCategoryList(List<SeriesCategory> categories) {
    final rowCount = (categories.length / 2).ceil();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: rowCount,
      cacheExtent: 500,
      itemBuilder: (context, rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        final hasRight = rightIndex < categories.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: SeriesCategoryCard(
                  category: categories[leftIndex],
                  onTap: () => _navigateToCategoryList(categories[leftIndex]),
                  autofocus: leftIndex == 0,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: hasRight
                    ? SeriesCategoryCard(
                        category: categories[rightIndex],
                        onTap: () =>
                            _navigateToCategoryList(categories[rightIndex]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
