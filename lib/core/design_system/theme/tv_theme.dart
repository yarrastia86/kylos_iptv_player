// Kylos IPTV Player - TV Theme
// Material 3 theme configuration for TV devices with larger touch targets.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/core/design_system/theme/app_colors.dart';
import 'package:kylos_iptv_player/core/design_system/theme/app_theme.dart';

/// TV-specific theme with larger touch targets and focus indicators.
///
/// Extends the base app theme with adjustments for 10-foot UI:
/// - Larger text for viewing distance
/// - More prominent focus indicators
/// - Increased spacing and card sizes
abstract class TvTheme {
  TvTheme._();

  /// Dark theme for TV devices.
  static ThemeData dark() {
    final base = AppTheme.dark();

    return base.copyWith(
      // Larger text for TV viewing distance
      textTheme: base.textTheme.apply(
        fontSizeFactor: 1.2,
      ),

      // Larger icons
      iconTheme: base.iconTheme.copyWith(
        size: 28,
      ),

      // Focus indicators for D-pad navigation
      focusColor: AppColors.focusGlow,

      // Larger cards for easier navigation
      cardTheme: base.cardTheme.copyWith(
        margin: const EdgeInsets.all(8),
      ),

      // Navigation rail adjustments
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 32,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 28,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
        minWidth: 80,
        minExtendedWidth: 200,
        useIndicator: true,
        indicatorColor: AppColors.primaryContainer,
      ),

      // Larger filled buttons for TV
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Light theme for TV devices.
  static ThemeData light() {
    final base = AppTheme.light();

    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: 1.2),
      iconTheme: base.iconTheme.copyWith(size: 28),
      focusColor: AppColors.focusGlow,
    );
  }
}
