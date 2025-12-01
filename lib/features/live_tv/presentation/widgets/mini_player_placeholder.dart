// Kylos IPTV Player - Mini Player Placeholder Widget
// Placeholder widget for the mini player preview.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

/// Mini player placeholder widget.
///
/// Displays a 16:9 placeholder showing the channel logo and name
/// until actual video playback is implemented.
class MiniPlayerPlaceholder extends StatelessWidget {
  const MiniPlayerPlaceholder({
    super.key,
    this.channel,
  });

  /// The currently selected channel (if any).
  final Channel? channel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: KylosColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KylosColors.surfaceLight,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: channel != null ? _buildChannelPreview() : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv,
            size: 48,
            color: KylosColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a channel',
            style: TextStyle(
              color: KylosColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPreview() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KylosColors.backgroundStart.withOpacity(0.8),
                KylosColors.backgroundEnd.withOpacity(0.9),
              ],
            ),
          ),
        ),

        // Channel logo (centered)
        if (channel!.logoUrl != null && channel!.logoUrl!.isNotEmpty)
          Center(
            child: CachedNetworkImage(
              imageUrl: channel!.logoUrl!,
              width: 120,
              height: 80,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Icon(
                Icons.tv,
                color: KylosColors.textMuted,
                size: 48,
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.tv,
                color: KylosColors.textMuted,
                size: 48,
              ),
            ),
          )
        else
          const Center(
            child: Icon(
              Icons.tv,
              color: KylosColors.textMuted,
              size: 48,
            ),
          ),

        // Overlay gradient at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Row(
              children: [
                // Channel number badge
                if (channel!.channelNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: KylosColors.liveTvGlow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      channel!.channelNumber.toString().padLeft(3, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Channel name
                Expanded(
                  child: Text(
                    channel!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // "Live" badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Play overlay hint
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }
}
