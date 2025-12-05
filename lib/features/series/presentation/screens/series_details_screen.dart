// Kylos IPTV Player - Series Details Screen
// Screen for displaying seasons and episodes of a series.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/episode.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series_info.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

class SeriesDetailsScreen extends ConsumerWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesInfoAsync = ref.watch(seriesInfoProvider(seriesId));

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
        child: seriesInfoAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: KylosColors.seriesGlow),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading series details: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (seriesInfo) => _buildContent(context, ref, seriesInfo),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SeriesInfo seriesInfo) {
    return DefaultTabController(
      length: seriesInfo.seasons.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              floating: false,
              backgroundColor: KylosColors.backgroundEnd,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  seriesInfo.info.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      seriesInfo.info.coverUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const SizedBox(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            KylosColors.backgroundEnd.withOpacity(0.8),
                            KylosColors.backgroundEnd,
                          ],
                          stops: const [0.5, 0.9, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  seriesInfo.info.plot ?? 'No description available.',
                  style: const TextStyle(
                    color: KylosColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  isScrollable: true,
                  indicatorColor: KylosColors.seriesGlow,
                  labelColor: KylosColors.seriesGlow,
                  unselectedLabelColor: KylosColors.textMuted,
                  tabs: seriesInfo.seasons
                      .map((s) => Tab(text: s.name.toUpperCase()))
                      .toList(),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          children: seriesInfo.seasons
              .map((s) => _buildEpisodeList(context, ref, s.episodes, seriesInfo))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEpisodeList(BuildContext context, WidgetRef ref, List<Episode> episodes, SeriesInfo seriesInfo) {
    if (episodes.isEmpty) {
      return const Center(
        child: Text(
          'No episodes in this season.',
          style: TextStyle(color: KylosColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return Card(
          color: KylosColors.surfaceDark.withOpacity(0.5),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KylosColors.seriesGlow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  episode.episodeNum?.toString() ?? (index + 1).toString(),
                  style: const TextStyle(
                    color: KylosColors.seriesGlow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              episode.title,
              style: const TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: episode.plot != null
                ? Text(
                    episode.plot!,
                    style: const TextStyle(
                      color: KylosColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(
              Icons.play_circle_outline,
              color: KylosColors.seriesGlow,
            ),
            onTap: () => _playEpisode(context, ref, episode, seriesInfo),
          ),
        );
      },
    );
  }

  void _playEpisode(BuildContext context, WidgetRef ref, Episode episode, SeriesInfo seriesInfo) {
    final repository = ref.read(seriesRepositoryProvider);
    final streamUrl = repository.getEpisodeStreamUrl(
      episode.id,
      episode.containerExtension,
    );

    final content = PlayableContent(
      id: episode.id,
      title: '${seriesInfo.info.name} - ${episode.title}',
      streamUrl: streamUrl,
      type: ContentType.episode,
      logoUrl: seriesInfo.info.coverUrl,
    );

    ref.read(playbackNotifierProvider.notifier).play(content);
    context.push(Routes.player);
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: KylosColors.backgroundEnd,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
