// Kylos IPTV Player - Series List Screen
// Screen for displaying series in a category.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/l10n/app_localizations.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for displaying series in a category.
///
/// Features a two-column layout with:
/// - LEFT: Scrollable series list
/// - RIGHT: Series info panel
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  /// The ID of the category to display series for.
  final String categoryId;

  /// Optional display name of the category.
  final String? categoryName;

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load series for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeries();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    final notifier = ref.read(seriesItemListNotifierProvider.notifier);
    // Pass the categoryId directly - selectCategory handles special categories
    await notifier.selectCategory(widget.categoryId);
  }

  void _handleBack() {
    context.go(Routes.series);
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  void _handleMore() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.optionsComingSoon)),
    );
  }

  void _onSeriesSelected(int index, Series series) {
    setState(() => _selectedIndex = index);
    context.push(Routes.seriesDetailPath(series.id));
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesItemListNotifierProvider);

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
              _buildBottomHints(),
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
          Expanded(
            child: Center(
              child: Text(
                widget.categoryName?.toUpperCase() ?? 'SERIES',
                style: const TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 20,
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

  Widget _buildContent(SeriesItemListState seriesState) {
    if (seriesState.isLoading && seriesState.series.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.seriesGlow,
        ),
      );
    }

    if (seriesState.error != null) {
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
              'Failed to load series',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),
            Text(
              seriesState.error!,
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KylosSpacing.l),
            FilledButton.icon(
              onPressed: _loadSeries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (seriesState.series.isEmpty) {
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
              'No series in this category',
              style: TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left: Series list (60%)
        Expanded(
          flex: 6,
          child: _buildSeriesList(seriesState),
        ),
        // Right: Series Info (40%)
        Expanded(
          flex: 4,
          child: _buildSeriesInfo(
            seriesState.series.isNotEmpty && _selectedIndex < seriesState.series.length
                ? seriesState.series[_selectedIndex]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesList(SeriesItemListState state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            ref.read(seriesItemListNotifierProvider.notifier).loadNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: state.series.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.series.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: KylosColors.seriesGlow,
                ),
              ),
            );
          }

          final series = state.series[index];
          final isSelected = index == _selectedIndex;

          return _buildSeriesRow(series, index, isSelected);
        },
      ),
    );
  }

  Widget _buildSeriesRow(Series series, int index, bool isSelected) {
    return InkWell(
      onTap: () => _onSeriesSelected(index, series),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KylosColors.seriesGlow.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: KylosColors.seriesGlow, width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 50,
                height: 70,
                child: series.coverUrl != null
                    ? Image.network(
                        series.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: KylosColors.surfaceDark,
                          child: const Icon(
                            Icons.tv,
                            color: KylosColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        color: KylosColors.surfaceDark,
                        child: const Icon(
                          Icons.tv,
                          color: KylosColors.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.name,
                    style: TextStyle(
                      color: isSelected
                          ? KylosColors.seriesGlow
                          : KylosColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (series.releaseDate != null || series.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (series.releaseDate != null) ...[
                          Text(
                            series.releaseDate!.split('-').first,
                            style: const TextStyle(
                              color: KylosColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (series.rating != null) const SizedBox(width: 8),
                        ],
                        if (series.rating != null) ...[
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            series.rating!,
                            style: const TextStyle(
                              color: KylosColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Favorite button
            IconButton(
              icon: Icon(
                series.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: series.isFavorite ? Colors.red : KylosColors.textMuted,
              ),
              onPressed: () {
                ref.read(seriesItemListNotifierProvider.notifier).toggleFavorite(series.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesInfo(Series? series) {
    if (series == null) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KylosColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Select a series',
            style: TextStyle(color: KylosColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Cover image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: series.coverUrl != null
                  ? Image.network(
                      series.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: KylosColors.surfaceDark,
                        child: const Center(
                          child: Icon(
                            Icons.tv,
                            size: 48,
                            color: KylosColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: KylosColors.surfaceDark,
                      child: const Center(
                        child: Icon(
                          Icons.tv,
                          size: 48,
                          color: KylosColors.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
          // Info
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        color: KylosColors.seriesGlow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (series.releaseDate != null) ...[
                          const Icon(Icons.calendar_today, size: 14, color: KylosColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            series.releaseDate!.split('-').first,
                            style: const TextStyle(color: KylosColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (series.rating != null) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            series.rating!,
                            style: const TextStyle(color: KylosColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (series.genre != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        series.genre!,
                        style: const TextStyle(
                          color: KylosColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (series.plot != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        series.plot!,
                        style: const TextStyle(
                          color: KylosColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (series.director != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Director: ${series.director}',
                        style: const TextStyle(
                          color: KylosColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (series.cast != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cast: ${series.cast}',
                        style: const TextStyle(
                          color: KylosColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHints() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _HintChip(icon: Icons.arrow_upward, label: 'Navigate'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.check, label: 'View'),
          SizedBox(width: 16),
          _HintChip(icon: Icons.favorite, label: 'Favorite'),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: KylosColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: KylosColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
