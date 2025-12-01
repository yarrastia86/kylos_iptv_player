// Kylos IPTV Player - Player Error View
// Error display for the video player.

import 'package:flutter/material.dart';

/// Error view displayed when playback fails.
class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.message,
    this.isRecoverable = true,
    this.onRetry,
    this.onBack,
  });

  /// Error message to display.
  final String message;

  /// Whether the error can be recovered from.
  final bool isRecoverable;

  /// Callback when retry is pressed.
  final VoidCallback? onRetry;

  /// Callback when back is pressed.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Icon(
                isRecoverable ? Icons.signal_wifi_off : Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),

              // Error title
              Text(
                isRecoverable ? 'Playback Error' : 'Cannot Play',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Error message
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button
                  if (onBack != null)
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),

                  if (onBack != null && isRecoverable && onRetry != null)
                    const SizedBox(width: 16),

                  // Retry button
                  if (isRecoverable && onRetry != null)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
