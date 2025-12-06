// Kylos IPTV Player - Series List Screen
// Screen for displaying series in a category with a proper aligned grid.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/features/series/presentation/widgets/series_poster_card.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for displaying series in a category.
///
/// Features a lean-back TV-optimized layout with:
/// - Proper rectangular grid with uniform spacing
/// - Responsive column count based on screen width
/// - Symmetric padding on all sides
/// - Press Select to view series details
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  final String categoryId;
  final String? categoryName;

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeries();
    });

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
      ref.read(seriesItemListNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _loadSeries() async {
    final notifier = ref.read(seriesItemListNotifierProvider.notifier);
    await notifier.selectCategory(widget.categoryId);
  }

  void _handleBack() {
    context.go(Routes.series);
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

  void _onSeriesSelect(Series series) {
    context.push(Routes.seriesDetailPath(series.id));
  }

  void _onSeriesFavoriteToggle(Series series) {
    ref.read(seriesItemListNotifierProvider.notifier).toggleFavorite(series.id);
  }

  int _calculateColumnCount(double screenWidth) {
    if (screenWidth >= 1400) return 7;
    if (screenWidth >= 1200) return 6;
    if (screenWidth >= 900) return 5;
    if (screenWidth >= 700) return 4;
    if (screenWidth >= 500) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesItemListNotifierProvider);

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
                  child: _buildContent(seriesState),
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
              widget.categoryName?.toUpperCase() ?? 'SERIES',
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

  Widget _buildContent(SeriesItemListState seriesState) {
    if (seriesState.isLoading && seriesState.series.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.seriesGlow,
        ),
      );
    }

    if (seriesState.error != null) {
      return _buildErrorState(seriesState.error!);
    }

    if (seriesState.series.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSeriesGrid(seriesState);
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
              'Failed to load series',
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
              onPressed: _loadSeries,
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
            Icons.tv_off_outlined,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            'No series in this category',
            style: KylosTvTextStyles.sectionHeader.copyWith(
              color: KylosColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesGrid(SeriesItemListState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columnCount = _calculateColumnCount(screenWidth);

        const horizontalPadding = KylosSpacing.xl;
        const gridSpacing = KylosSpacing.m;

        final totalHorizontalPadding = horizontalPadding * 2;
        final totalSpacing = gridSpacing * (columnCount - 1);
        final availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
        final cardWidth = availableWidth / columnCount;

        final posterHeight = cardWidth * 1.5;
        const titleAreaHeight = 60.0;
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
          itemCount: state.series.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.series.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(KylosSpacing.l),
                  child: CircularProgressIndicator(
                    color: KylosColors.seriesGlow,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final series = state.series[index];
            return _SeriesGridCard(
              series: series,
              autofocus: index == 0,
              onSelect: () => _onSeriesSelect(series),
              onLongPress: () => _onSeriesFavoriteToggle(series),
            );
          },
        );
      },
    );
  }
}

class _SeriesGridCard extends StatelessWidget {
  const _SeriesGridCard({
    required this.series,
    required this.onSelect,
    this.onLongPress,
    this.autofocus = false,
  });

  final Series series;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SeriesPosterCard(
          series: series,
          width: constraints.maxWidth,
          autofocus: autofocus,
          onSelect: onSelect,
          onLongPress: onLongPress,
        );
      },
    );
  }
}

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
                  ? KylosColors.seriesGlow.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.s),
              border: _isFocused
                  ? Border.all(color: KylosColors.seriesGlow, width: 2)
                  : null,
            ),
            child: Icon(
              widget.icon,
              color:
                  _isFocused ? KylosColors.seriesGlow : KylosColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

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
            color: _isFocused ? KylosColors.seriesGlow : KylosColors.surfaceLight,
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: KylosColors.seriesGlow, width: 2)
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
