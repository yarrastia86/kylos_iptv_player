// Kylos IPTV Player - Bottom Hints Row Widget
// Row widget for displaying keyboard/remote button hints.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// Row widget for displaying action button hints at the bottom of the screen.
///
/// Shows hints for common actions like Play, Favorite, OK, and Back.
class BottomHintsRow extends StatelessWidget {
  const BottomHintsRow({
    super.key,
    this.showFavorite = true,
    this.isFavorite = false,
  });

  /// Whether to show the favorite hint.
  final bool showFavorite;

  /// Whether the current item is favorited.
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: KylosColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: KylosColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // OK / Select hint
          _buildHintItem(
            icon: Icons.check_circle_outline,
            label: 'OK',
            accentColor: KylosColors.liveTvGlow,
          ),

          const SizedBox(width: 32),

          // Play hint
          _buildHintItem(
            icon: Icons.play_circle_outline,
            label: 'Play',
          ),

          if (showFavorite) ...[
            const SizedBox(width: 32),

            // Favorite hint
            _buildHintItem(
              icon: isFavorite ? Icons.star : Icons.star_border,
              label: 'Favorite',
              accentColor: isFavorite ? Colors.amber : null,
            ),
          ],

          const SizedBox(width: 32),

          // Back hint
          _buildHintItem(
            icon: Icons.arrow_back,
            label: 'Back',
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem({
    required IconData icon,
    required String label,
    Color? accentColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accentColor?.withOpacity(0.2) ??
                KylosColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: accentColor?.withOpacity(0.5) ??
                  KylosColors.textMuted.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: accentColor ?? KylosColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: KylosColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
