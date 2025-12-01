// Kylos IPTV Player - Channel List Tile
// Widget for displaying a channel in a list.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel.dart';

/// A list tile widget for displaying a channel.
class ChannelListTile extends StatelessWidget {
  const ChannelListTile({
    super.key,
    required this.channel,
    this.isPlaying = false,
    this.epgTitle,
    this.onTap,
    this.onFavoriteToggle,
    this.onLongPress,
  });

  /// The channel to display.
  final Channel channel;

  /// Whether this channel is currently playing.
  final bool isPlaying;

  /// Current program title from EPG.
  final String? epgTitle;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when favorite is toggled.
  final VoidCallback? onFavoriteToggle;

  /// Called when the tile is long pressed.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isPlaying,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      leading: _buildLogo(context),
      title: Text(
        channel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: epgTitle != null
          ? Text(
              epgTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : channel.channelNumber != null
              ? Text(
                  'Ch. ${channel.channelNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Playing indicator
          if (isPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Favorite button
          if (onFavoriteToggle != null)
            IconButton(
              icon: Icon(
                channel.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: channel.isFavorite ? Colors.red : null,
              ),
              onPressed: onFavoriteToggle,
            ),

          // Locked indicator
          if (channel.isLocked)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.lock, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    const logoSize = 48.0;

    if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: channel.logoUrl!,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          placeholder: (_, __) => _buildPlaceholder(context),
          errorWidget: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.live_tv,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
