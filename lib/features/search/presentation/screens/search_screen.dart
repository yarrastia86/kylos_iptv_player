// Kylos IPTV Player - Search Screen
// Screen for searching content across the app (movies and series).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/features/vod/domain/entities/vod_movie.dart';
import 'package:kylos_iptv_player/features/vod/presentation/providers/vod_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Tab selection for search results.
enum SearchTab { movies, series }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  SearchTab _selectedTab = SearchTab.movies;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = SearchTab.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;

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
              // Search header
              _buildSearchHeader(),

              // Tab bar
              _buildTabBar(),

              // Results
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMovieResults(query),
                    _buildSeriesResults(query),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(KylosSpacing.m),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: KylosColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search movies and series...',
                hintStyle: const TextStyle(color: KylosColors.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: KylosColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: KylosColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: KylosColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: KylosColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: KylosColors.moviesGlow.withOpacity(0.2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: KylosColors.moviesGlow,
        unselectedLabelColor: KylosColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.movie, size: 20),
            text: 'Movies',
          ),
          Tab(
            icon: Icon(Icons.tv, size: 20),
            text: 'Series',
          ),
        ],
      ),
    );
  }

  Widget _buildMovieResults(String query) {
    if (query.length < 2) {
      return _buildEmptyState('Enter at least 2 characters to search movies');
    }

    final moviesAsync = ref.watch(movieSearchProvider(query));

    return moviesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KylosColors.moviesGlow),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: KylosColors.textMuted),
        ),
      ),
      data: (movies) {
        if (movies.isEmpty) {
          return _buildEmptyState('No movies found for "$query"');
        }
        return _buildMovieList(movies);
      },
    );
  }

  Widget _buildSeriesResults(String query) {
    if (query.length < 2) {
      return _buildEmptyState('Enter at least 2 characters to search series');
    }

    final seriesAsync = ref.watch(seriesSearchProvider(query));

    return seriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KylosColors.seriesGlow),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: KylosColors.textMuted),
        ),
      ),
      data: (series) {
        if (series.isEmpty) {
          return _buildEmptyState('No series found for "$query"');
        }
        return _buildSeriesList(series);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTab == SearchTab.movies ? Icons.movie : Icons.tv,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            message,
            style: const TextStyle(
              color: KylosColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovieList(List<VodMovie> movies) {
    return ListView.builder(
      padding: const EdgeInsets.all(KylosSpacing.m),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _SearchResultCard(
          title: movie.name,
          subtitle: movie.categoryName ?? movie.genre,
          imageUrl: movie.posterUrl,
          rating: movie.rating,
          icon: Icons.movie,
          glowColor: KylosColors.moviesGlow,
          onTap: () => context.push(Routes.movieDetailPath(movie.id)),
        );
      },
    );
  }

  Widget _buildSeriesList(List<Series> series) {
    return ListView.builder(
      padding: const EdgeInsets.all(KylosSpacing.m),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final item = series[index];
        return _SearchResultCard(
          title: item.name,
          subtitle: item.categoryName ?? item.genre,
          imageUrl: item.coverUrl,
          rating: item.rating,
          icon: Icons.tv,
          glowColor: KylosColors.seriesGlow,
          onTap: () => context.push(Routes.seriesDetailPath(item.id)),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.rating,
    required this.icon,
    required this.glowColor,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? rating;
  final IconData icon;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: KylosColors.surfaceDark.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: KylosSpacing.s),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(KylosSpacing.s),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: _buildImage(),
                ),
              ),
              const SizedBox(width: KylosSpacing.m),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: KylosColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: KylosColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (rating != null && rating!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating!,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: glowColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildPlaceholder(),
        placeholder: (_, __) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KylosColors.surfaceDark,
      child: Center(
        child: Icon(
          icon,
          color: KylosColors.textMuted,
          size: 24,
        ),
      ),
    );
  }
}
