// Kylos IPTV Player - Continue Watching Section
// Widget showing content the user can resume watching.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_providers.dart';
import 'package:kylos_iptv_player/core/domain/playback/playback_state.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_history_providers.dart';
import 'package:kylos_iptv_player/core/domain/watch_history/watch_progress.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Section displaying content the user can continue watching.
class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatchingAsync = ref.watch(continueWatchingProvider);

    return continueWatchingAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildSection(context, ref, items);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    List<WatchProgress> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.m,
            vertical: KylosSpacing.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Continue Watching',
                style: TextStyle(
                  color: KylosColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Horizontal scrolling list
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KylosSpacing.m),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < items.length - 1 ? KylosSpacing.s : 0,
                ),
                child: ContinueWatchingCard(
                  progress: items[index],
                  onTap: () => _onItemTap(context, ref, items[index]),
                  onRemove: () => _onItemRemove(ref, items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onItemTap(BuildContext context, WidgetRef ref, WatchProgress progress) {
    if (progress.streamUrl == null) {
      // Navigate to details screen to get stream URL
      if (progress.contentType == WatchContentType.movie) {
        context.push(Routes.movieDetailPath(progress.contentId));
      } else if (progress.seriesId != null) {
        context.push(Routes.seriesDetailPath(progress.seriesId!));
      }
      return;
    }

    // Direct playback
    final content = PlayableContent(
      id: progress.contentId,
      title: progress.title,
      streamUrl: progress.streamUrl!,
      type: progress.contentType == WatchContentType.movie
          ? ContentType.vod
          : ContentType.episode,
      logoUrl: progress.posterUrl,
      resumePosition: progress.position,
      duration: progress.duration,
    );

    ref.read(playbackNotifierProvider.notifier).play(content);
    context.push(Routes.player);
  }

  void _onItemRemove(WidgetRef ref, WatchProgress progress) {
    ref
        .read(watchProgressNotifierProvider.notifier)
        .removeProgress(progress.contentId);
    ref.invalidate(continueWatchingProvider);
  }
}

/// Card for a single continue watching item.
class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard({
    super.key,
    required this.progress,
    required this.onTap,
    required this.onRemove,
  });

  final WatchProgress progress;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with progress bar
            Expanded(
              child: Stack(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildThumbnail(),
                  ),

                  // Play button overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black26,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                  ),

                  // Progress bar at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: LinearProgressIndicator(
                        value: progress.progress,
                        backgroundColor: Colors.black45,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress.contentType == WatchContentType.movie
                              ? KylosColors.moviesGlow
                              : KylosColors.seriesGlow,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KylosSpacing.xs),

            // Title
            Text(
              progress.title,
              style: const TextStyle(
                color: KylosColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Subtitle (for episodes)
            if (progress.episodeSubtitle != null ||
                progress.seriesName != null) ...[
              Text(
                progress.episodeSubtitle ?? progress.seriesName ?? '',
                style: const TextStyle(
                  color: KylosColors.textMuted,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Remaining time
            Text(
              _formatRemaining(progress.remaining),
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (progress.posterUrl != null && progress.posterUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: progress.posterUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
          progress.contentType == WatchContentType.movie
              ? Icons.movie
              : Icons.tv,
          color: KylosColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
    }
    return '${remaining.inMinutes}m left';
  }
}
