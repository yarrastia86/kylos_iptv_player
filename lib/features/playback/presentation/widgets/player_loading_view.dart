// Kylos IPTV Player - Player Loading View
// Loading indicator for the video player.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Loading view displayed while video is loading or buffering.
class PlayerLoadingView extends StatelessWidget {
  const PlayerLoadingView({
    super.key,
    this.message,
    this.channelName,
    this.channelLogo,
  });

  /// Loading message to display.
  final String? message;

  /// Name of the channel being loaded.
  final String? channelName;

  /// Logo URL of the channel.
  final String? channelLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Channel logo
            if (channelLogo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: channelLogo!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 80,
                    height: 80,
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.live_tv,
                    size: 60,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Channel name
            if (channelName != null) ...[
              Text(
                channelName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),

            // Loading message
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
