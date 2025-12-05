// Kylos IPTV Player - Live TV Categories Screen
// Screen displaying Live TV categories in a two-column layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_category_card.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_overflow_menu.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen displaying Live TV categories.
///
/// Shows categories in a two-column layout on wide screens,
/// single column on narrow screens.
class LiveTvCategoriesScreen extends ConsumerStatefulWidget {
  const LiveTvCategoriesScreen({super.key});

  @override
  ConsumerState<LiveTvCategoriesScreen> createState() =>
      _LiveTvCategoriesScreenState();
}

class _LiveTvCategoriesScreenState
    extends ConsumerState<LiveTvCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelListNotifierProvider.notifier).loadChannels();
    });
  }

  void _navigateToChannelList(ChannelCategory category) {
    context.push(
      Routes.liveTvCategoryPath(category.id),
      extra: category.name,
    );
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  Future<void> _handleMore() async {
    final selectedItemId = await showLiveTvOverflowMenu(context);
    if (selectedItemId == null || !mounted) return;

    switch (selectedItemId) {
      case 'home':
        _handleNavigateHome();
      case 'refresh_content':
        await _handleRefreshContent();
      case 'refresh_epg':
        await _handleRefreshEpg();
      case 'sort':
        _handleShowSortOptions();
      case 'settings':
        _handleNavigateSettings();
      case 'logout':
        await _handleLogout();
    }
  }

  void _handleNavigateHome() {
    context.go(Routes.dashboard);
  }

  Future<void> _handleRefreshContent() async {
    await ref.read(channelListNotifierProvider.notifier).refresh();
  }

  Future<void> _handleRefreshEpg() async {
    await ref.read(channelEpgNotifierProvider.notifier).refresh();
  }

  void _handleShowSortOptions() {
    _showSortDialog();
  }

  void _handleNavigateSettings() {
    context.push(Routes.settings);
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
      // Clear active playlist
      ref.read(activePlaylistNotifierProvider.notifier).clearActivePlaylist();

      // Navigate to onboarding
      context.go(Routes.onboarding);
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Sort Categories',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Name (A-Z)', Icons.sort_by_alpha, 'name_asc'),
            _buildSortOption('Name (Z-A)', Icons.sort_by_alpha, 'name_desc'),
            _buildSortOption('Channel Count', Icons.numbers, 'count'),
            _buildSortOption('Default', Icons.restore, 'default'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon, String sortType) {
    return ListTile(
      leading: Icon(icon, color: KylosColors.textSecondary),
      title: Text(
        label,
        style: const TextStyle(color: KylosColors.textPrimary),
      ),
      onTap: () {
        Navigator.pop(context);
        // TODO: Implement actual sorting logic
      },
    );
  }

  void _handleBack() {
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelListNotifierProvider);

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
              // Top bar
              _buildTopBar(),

              // Main content
              Expanded(
                child: _buildContent(channelState),
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
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: KylosColors.textPrimary),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),

          // Title centered
          const Expanded(
            child: Center(
              child: Text(
                'LIVE TV',
                style: TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Search and menu buttons
          IconButton(
            icon:
                const Icon(Icons.search, color: KylosColors.textSecondary),
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

  Widget _buildContent(ChannelListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.liveTvGlow,
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
            Text(
              'Failed to load categories',
              style: const TextStyle(
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
                ref.read(channelListNotifierProvider.notifier).loadChannels();
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
          children: [
            const Icon(
              Icons.folder_open,
              size: 64,
              color: KylosColors.textMuted,
            ),
            const SizedBox(height: KylosSpacing.m),
            const Text(
              'No categories available',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            const Text(
              'Add a playlist to start watching',
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

    return _buildHorizontalLayout(categories);
  }

  List<ChannelCategory> _buildCategoriesWithSpecial(ChannelListState state) {
    // Create special categories
    final allCategory = ChannelCategory(
      id: 'all',
      name: 'ALL',
      channelCount: state.allChannelsCount, // Use allChannelsCount, not totalCount
      sortOrder: -2,
    );

    final favoritesCategory = ChannelCategory(
      id: 'favorites',
      name: 'FAVORITES',
      channelCount: state.favoritesCount, // Use favoritesCount from state (source of truth)
      sortOrder: -1,
      isFavorite: true,
    );

    // Combine: ALL, FAVORITES, then rest of categories
    return [allCategory, favoritesCategory, ...state.categories];
  }

  Widget _buildHorizontalLayout(List<ChannelCategory> categories) {
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
                child: LiveTvCategoryCard(
                  category: categories[leftIndex],
                  onTap: () => _navigateToChannelList(categories[leftIndex]),
                  autofocus: leftIndex == 0,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: hasRight
                    ? LiveTvCategoryCard(
                        category: categories[rightIndex],
                        onTap: () => _navigateToChannelList(categories[rightIndex]),
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
