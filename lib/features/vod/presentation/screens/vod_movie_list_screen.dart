// Kylos IPTV Player - VOD Movie List Screen
// Screen for displaying movies in a category with full-width poster grid.

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
/// - Full-width horizontal scrolling rows of movie posters
/// - Press Select to view movie details
/// - Clean, uncluttered interface optimized for 10-foot viewing
class VodMovieListScreen extends ConsumerStatefulWidget {
  const VodMovieListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  /// The ID of the category to display movies for.
  final String categoryId;

  /// Optional display name of the category.
  final String? categoryName;

  @override
  ConsumerState<VodMovieListScreen> createState() => _VodMovieListScreenState();
}

class _VodMovieListScreenState extends ConsumerState<VodMovieListScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _screenFocusNode = FocusNode();

  // Grid configuration - larger cards for TV
  static const _cardWidth = 150.0;
  static const _cardSpacing = 15.0;
  static const _rowHeight = 180.0 + 15.0; // Card height (180*1.5) + padding

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovies();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
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

    // Handle back button
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onMovieSelect(VodMovie movie) {
    // Navigate to movie details screen
    context.push(Routes.movieDetailPath(movie.id));
  }

  void _onMovieFavoriteToggle(VodMovie movie) {
    ref.read(movieListNotifierProvider.notifier).toggleFavorite(movie.id);
  }

  /// Calculate how many movies fit per row based on available width.
  int _calculateMoviesPerRow(double availableWidth) {
    const totalCardWidth = _cardWidth + _cardSpacing;
    return ((availableWidth - KylosSpacing.xxl * 2) / totalCardWidth)
        .floor()
        .clamp(3, 8);
  }

  /// Group movies into rows for horizontal scrolling.
  List<List<VodMovie>> _groupMoviesIntoRows(
      List<VodMovie> movies, int moviesPerRow) {
    final rows = <List<VodMovie>>[];
    for (var i = 0; i < movies.length; i += moviesPerRow) {
      final end =
          (i + moviesPerRow < movies.length) ? i + moviesPerRow : movies.length;
      rows.add(movies.sublist(i, end));
    }
    return rows;
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
        horizontal: KylosSpacing.l,
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
        final moviesPerRow = _calculateMoviesPerRow(constraints.maxWidth);
        final movieRows = _groupMoviesIntoRows(state.movies, moviesPerRow);

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 300) {
                ref.read(movieListNotifierProvider.notifier).loadNextPage();
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: KylosSpacing.m),
            itemCount: movieRows.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, rowIndex) {
              if (rowIndex >= movieRows.length) {
                return const Padding(
                  padding: EdgeInsets.all(KylosSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: KylosColors.tvAccent,
                    ),
                  ),
                );
              }

              final row = movieRows[rowIndex];
              return _buildMovieRow(row, rowIndex, rowIndex == 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildMovieRow(List<VodMovie> movies, int rowIndex, bool autofocusFirst) {
    return SizedBox(
      height: _rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.xxl),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final isFirst = rowIndex == 0 && index == 0;

          return Padding(
            padding: EdgeInsets.only(
              right: index < movies.length - 1 ? _cardSpacing : 0,
            ),
            child: MoviePosterCard(
              movie: movie,
              width: _cardWidth,
              autofocus: autofocusFirst && isFirst,
              onSelect: () => _onMovieSelect(movie),
              onLongPress: () => _onMovieFavoriteToggle(movie),
            ),
          );
        },
      ),
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
