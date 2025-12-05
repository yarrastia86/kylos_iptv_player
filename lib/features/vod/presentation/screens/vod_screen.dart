// Kylos IPTV Player - VOD Screen
// Screen for browsing video-on-demand movies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_providers.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_category.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/features/vod/presentation/widgets/vod_category_card.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Video on Demand (Movies) screen.
///
/// Displays available movies from the user's playlists organized
/// by categories. Features a "Continue Watching" section at the top
/// for quick access to recently viewed content.
class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vodListNotifierProvider.notifier).loadCategories();
    });
  }

  void _navigateToCategoryList(VodCategory category) {
    context.push(
      Routes.vodCategoryPath(category.id),
      extra: category.name,
    );
  }

  void _handleSearch() {
    context.push(Routes.search);
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
                // TODO: Implement sorting
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
    await ref.read(vodListNotifierProvider.notifier).refresh();
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

  void _onContinueWatchingSelect(WatchProgress progress) {
    // Navigate to movie details
    context.push(Routes.movieDetailPath(progress.contentId));
  }

  @override
  Widget build(BuildContext context) {
    final vodState = ref.watch(vodListNotifierProvider);
    final continueWatchingAsync = ref.watch(continueWatchingProvider);

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
                child: _buildContent(vodState, continueWatchingAsync),
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
                'MOVIES',
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

  Widget _buildContent(
    VodListState state,
    AsyncValue<List<WatchProgress>> continueWatchingAsync,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.moviesGlow,
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
                ref.read(vodListNotifierProvider.notifier).loadCategories();
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
              Icons.movie_outlined,
              size: 64,
              color: KylosColors.textMuted,
            ),
            SizedBox(height: KylosSpacing.m),
            Text(
              'No movies available',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: KylosSpacing.xs),
            Text(
              'Add a playlist with VOD content',
              style: TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Get continue watching movies only
    final continueWatchingMovies = continueWatchingAsync.whenOrNull(
      data: (items) => items
          .where((item) => item.contentType == WatchContentType.movie)
          .toList(),
    );

    // Build categories with ALL and FAVOURITES at top
    final categories = _buildCategoriesWithSpecial(state);

    return ListView(
      padding: const EdgeInsets.only(bottom: KylosSpacing.l),
      children: [
        // Continue Watching Section
        if (continueWatchingMovies != null && continueWatchingMovies.isNotEmpty)
          _buildContinueWatchingSection(continueWatchingMovies),

        // Categories Section Header
        Padding(
          padding: const EdgeInsets.only(
            left: KylosSpacing.m,
            top: KylosSpacing.m,
            bottom: KylosSpacing.s,
          ),
          child: Text(
            'Categories',
            style: const TextStyle(
              color: KylosColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),

        // Category Grid
        _buildCategoryGrid(categories),
      ],
    );
  }

  Widget _buildContinueWatchingSection(List<WatchProgress> items) {
    // Convert WatchProgress to fake VodMovie for display
    final movies = items
        .map((progress) => VodMovie(
              id: progress.contentId,
              name: progress.title,
              streamUrl: progress.streamUrl ?? '',
              posterUrl: progress.posterUrl,
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(
            left: KylosSpacing.xxl,
            right: KylosSpacing.m,
            top: KylosSpacing.s,
            bottom: KylosSpacing.s,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: KylosColors.moviesGlow,
                size: 22,
              ),
              const SizedBox(width: KylosSpacing.xs),
              const Text(
                'Continue Watching',
                style: TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // Horizontal movie row
        SizedBox(
          height: 225 + KylosSpacing.m, // Card height + padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.xxl),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final progress = items[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index < movies.length - 1 ? 16 : 0,
                ),
                child: _ContinueWatchingCard(
                  movie: movie,
                  progress: progress.progress,
                  autofocus: index == 0,
                  onSelect: () => _onContinueWatchingSelect(progress),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: KylosSpacing.s),
      ],
    );
  }

  List<VodCategory> _buildCategoriesWithSpecial(VodListState state) {
    final allCategory = VodCategory(
      id: 'all',
      name: 'ALL',
      movieCount: state.allMoviesCount,
      sortOrder: -2,
    );

    final favoritesCategory = VodCategory(
      id: 'favorites',
      name: 'FAVORITES',
      movieCount: state.favoritesCount,
      sortOrder: -1,
      isFavorite: true,
    );

    return [allCategory, favoritesCategory, ...state.categories];
  }

  Widget _buildCategoryGrid(List<VodCategory> categories) {
    final rowCount = (categories.length / 2).ceil();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        final hasRight = rightIndex < categories.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: VodCategoryCard(
                  category: categories[leftIndex],
                  onTap: () => _navigateToCategoryList(categories[leftIndex]),
                  autofocus: false, // Don't autofocus category cards
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: hasRight
                    ? VodCategoryCard(
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

/// A continue watching card with progress indicator.
class _ContinueWatchingCard extends StatefulWidget {
  const _ContinueWatchingCard({
    required this.movie,
    required this.progress,
    this.autofocus = false,
    this.onSelect,
  });

  final VodMovie movie;
  final double progress;
  final bool autofocus;
  final VoidCallback? onSelect;

  @override
  State<_ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<_ContinueWatchingCard>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  static const _cardWidth = 150.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: KylosDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() => _isFocused = hasFocus);
      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = _cardWidth * 1.5;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: KylosDurations.fast,
                width: _cardWidth,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KylosRadius.m),
                  border: _isFocused
                      ? Border.all(
                          color: KylosColors.moviesGlow,
                          width: 3,
                        )
                      : null,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: KylosColors.moviesGlow.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _isFocused ? KylosRadius.m - 3 : KylosRadius.m,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Poster image
                      _buildPoster(),

                      // Bottom gradient
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: height * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                KylosColors.backgroundStart.withOpacity(0.7),
                                KylosColors.backgroundStart.withOpacity(0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Progress bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: widget.progress,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            KylosColors.moviesGlow,
                          ),
                          minHeight: 4,
                        ),
                      ),

                      // Title
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 12,
                        child: Text(
                          widget.movie.name,
                          style: TextStyle(
                            color: _isFocused
                                ? KylosColors.moviesGlow
                                : KylosColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Play icon overlay
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isFocused
                                ? KylosColors.moviesGlow.withOpacity(0.9)
                                : Colors.white.withOpacity(0.8),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: _isFocused ? Colors.white : Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.movie.posterUrl;
    if (posterUrl != null && posterUrl.isNotEmpty) {
      return Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: Center(
        child: Icon(
          Icons.movie,
          size: _cardWidth * 0.3,
          color: KylosColors.textMuted,
        ),
      ),
    );
  }
}
