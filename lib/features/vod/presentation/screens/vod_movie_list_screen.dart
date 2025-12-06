// Kylos IPTV Player - VOD Movie List Screen
// Screen for displaying movies in a category with a proper aligned grid.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/features/vod/presentation/widgets/movie_poster_card.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for displaying movies in a category.
///
/// Features a lean-back TV-optimized layout with:
/// - Proper rectangular grid with uniform spacing
/// - Responsive column count based on screen width
/// - Symmetric padding on all sides
/// - Press Select to view movie details
class VodMovieListScreen extends ConsumerStatefulWidget {
  const VodMovieListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  final String categoryId;
  final String? categoryName;

  @override
  ConsumerState<VodMovieListScreen> createState() => _VodMovieListScreenState();
}

class _VodMovieListScreenState extends ConsumerState<VodMovieListScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(movieListNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _loadMovies() async {
    final notifier = ref.read(movieListNotifierProvider.notifier);
    await notifier.selectCategory(widget.categoryId);
  }

  void _handleBack() {
    context.go(Routes.vod);
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onMovieSelect(VodMovie movie) {
    context.push(Routes.movieDetailPath(movie.id));
  }

  void _onMovieFavoriteToggle(VodMovie movie) {
    ref.read(movieListNotifierProvider.notifier).toggleFavorite(movie.id);
  }

  /// Calculate the number of columns based on screen width.
  /// Returns responsive column count for different device sizes.
  int _calculateColumnCount(double screenWidth) {
    if (screenWidth >= 1400) return 7; // Large TV
    if (screenWidth >= 1200) return 6; // TV
    if (screenWidth >= 900) return 5;  // Large tablet landscape
    if (screenWidth >= 700) return 4;  // Tablet
    if (screenWidth >= 500) return 3;  // Large phone landscape
    return 2; // Phone portrait
  }

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieListNotifierProvider);

    return Focus(
      focusNode: _screenFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
                  child: _buildContent(movieState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xl,
        vertical: KylosSpacing.m,
      ),
      child: Row(
        children: [
          _FocusableIconButton(
            icon: Icons.arrow_back,
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: KylosSpacing.m),
          Expanded(
            child: Text(
              widget.categoryName?.toUpperCase() ?? 'MOVIES',
              style: KylosTvTextStyles.screenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _FocusableIconButton(
            icon: Icons.search,
            onPressed: _handleSearch,
            tooltip: 'Search',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MovieListState movieState) {
    if (movieState.isLoading && movieState.movies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.tvAccent,
        ),
      );
    }

    if (movieState.error != null) {
      return _buildErrorState(movieState.error!);
    }

    if (movieState.movies.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMovieGrid(movieState);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KylosSpacing.xl),
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
              'Failed to load movies',
              style: KylosTvTextStyles.sectionHeader.copyWith(
                color: KylosColors.textPrimary,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            Text(
              error,
              style: KylosTvTextStyles.body.copyWith(
                color: KylosColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KylosSpacing.xl),
            _FocusableButton(
              icon: Icons.refresh,
              label: 'Retry',
              onPressed: _loadMovies,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_outlined,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            'No movies in this category',
            style: KylosTvTextStyles.sectionHeader.copyWith(
              color: KylosColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(MovieListState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columnCount = _calculateColumnCount(screenWidth);

        // Calculate card dimensions for proper aspect ratio (2:3 poster)
        // Account for horizontal padding and spacing between cards
        const horizontalPadding = KylosSpacing.xl; // 32px on each side
        const gridSpacing = KylosSpacing.m; // 16px between cards

        final totalHorizontalPadding = horizontalPadding * 2;
        final totalSpacing = gridSpacing * (columnCount - 1);
        final availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
        final cardWidth = availableWidth / columnCount;

        // Poster aspect ratio is 2:3, plus space for title below
        // Card height = poster height + title area
        final posterHeight = cardWidth * 1.5;
        final titleAreaHeight = 60.0; // Fixed space for title and year
        final cardHeight = posterHeight + titleAreaHeight;

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: KylosSpacing.m,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: gridSpacing,
            crossAxisSpacing: gridSpacing,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: state.movies.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end
            if (index >= state.movies.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(KylosSpacing.l),
                  child: CircularProgressIndicator(
                    color: KylosColors.tvAccent,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final movie = state.movies[index];
            return _MovieGridCard(
              movie: movie,
              autofocus: index == 0,
              onSelect: () => _onMovieSelect(movie),
              onLongPress: () => _onMovieFavoriteToggle(movie),
            );
          },
        );
      },
    );
  }
}

/// Movie card optimized for grid display.
/// Uses the existing MoviePosterCard but ensures proper sizing.
class _MovieGridCard extends StatelessWidget {
  const _MovieGridCard({
    required this.movie,
    required this.onSelect,
    this.onLongPress,
    this.autofocus = false,
  });

  final VodMovie movie;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available width from the grid cell
        return MoviePosterCard(
          movie: movie,
          width: constraints.maxWidth,
          autofocus: autofocus,
          onSelect: onSelect,
          onLongPress: onLongPress,
        );
      },
    );
  }
}

/// A focusable icon button for the top bar.
class _FocusableIconButton extends StatefulWidget {
  const _FocusableIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<_FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<_FocusableIconButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            padding: const EdgeInsets.all(KylosSpacing.s),
            decoration: BoxDecoration(
              color: _isFocused
                  ? KylosColors.tvAccent.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.s),
              border: _isFocused
                  ? Border.all(color: KylosColors.tvAccent, width: 2)
                  : null,
            ),
            child: Icon(
              widget.icon,
              color: _isFocused
                  ? KylosColors.tvAccent
                  : KylosColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// A focusable button for actions.
class _FocusableButton extends StatefulWidget {
  const _FocusableButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.l,
            vertical: KylosSpacing.m,
          ),
          decoration: BoxDecoration(
            color: _isFocused
                ? KylosColors.tvAccent
                : KylosColors.surfaceLight,
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: KylosColors.tvAccent, width: 2)
                : Border.all(color: KylosColors.buttonBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isFocused ? Colors.white : KylosColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: KylosSpacing.s),
              Text(
                widget.label,
                style: KylosTvTextStyles.button.copyWith(
                  color: _isFocused ? Colors.white : KylosColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
