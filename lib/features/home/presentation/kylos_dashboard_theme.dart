// Kylos IPTV Player - Dashboard Theme
// Design system constants for the dashboard screen.

import 'package:flutter/material.dart';

/// Spacing constants for consistent layout.
abstract class KylosSpacing {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Color palette for the dashboard.
abstract class KylosColors {
  // Background gradient
  static const Color backgroundStart = Color(0xFF050819);
  static const Color backgroundEnd = Color(0xFF0A1025);

  // Surface colors
  static const Color surfaceDark = Color(0xFF0D1229);
  static const Color surfaceLight = Color(0xFF151B36);
  static const Color surfaceOverlay = Color(0x1AFFFFFF); // 10% white

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textMuted = Color(0x80FFFFFF); // 50% white
  static const Color textCaption = Color(0x66FFFFFF); // 40% white

  // Accent gradients for tiles
  static const List<Color> liveTvGradient = [
    Color(0xFF00D4AA),
    Color(0xFF00B4D8),
  ];

  static const List<Color> moviesGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E53),
  ];

  static const List<Color> seriesGradient = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];

  // Glow colors (for shadows)
  static const Color liveTvGlow = Color(0xFF00D4AA);
  static const Color moviesGlow = Color(0xFFFF6B6B);
  static const Color seriesGlow = Color(0xFF667EEA);

  // TV-friendly accent (softer than saturated red/yellow)
  static const Color tvAccent = Color(0xFF7C9FFF); // Soft blue-purple
  static const Color tvAccentAlt = Color(0xFF00D4AA); // Cyan-teal

  // Button colors
  static const Color buttonBackground = Color(0x1AFFFFFF); // 10% white
  static const Color buttonBorder = Color(0x33FFFFFF); // 20% white
  static const Color buttonFocused = Color(0x33FFFFFF); // 20% white
}

/// Border radius constants.
abstract class KylosRadius {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 100;
}

/// Animation durations.
abstract class KylosDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
}

/// Text styles for the dashboard.
abstract class KylosTextStyles {
  // Time display (large)
  static const TextStyle time = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
  );

  // Date display
  static const TextStyle date = TextStyle(
    color: KylosColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // Brand name (KYLOS)
  static const TextStyle brandName = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 3,
  );

  // Brand tagline (IPTV PLAYER)
  static const TextStyle brandTagline = TextStyle(
    color: KylosColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
  );

  // Primary tile label
  static const TextStyle tileLabel = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
  );

  // Secondary button label
  static const TextStyle secondaryLabel = TextStyle(
    color: KylosColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  // Caption / footer text
  static const TextStyle caption = TextStyle(
    color: KylosColors.textCaption,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

/// TV-optimized text styles (10-foot experience).
/// Minimum 22px for body text, increased letter/line spacing.
abstract class KylosTvTextStyles {
  // Screen title (large header)
  static const TextStyle screenTitle = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.5,
    height: 1.3,
  );

  // Section header (category row titles)
  static const TextStyle sectionHeader = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.3,
  );

  // Card title (movie/show names)
  static const TextStyle cardTitle = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Card subtitle (year, rating)
  static const TextStyle cardSubtitle = TextStyle(
    color: KylosColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Body text (descriptions, plots)
  static const TextStyle body = TextStyle(
    color: KylosColors.textSecondary,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.5,
  );

  // Button label
  static const TextStyle button = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  // Badge text (HD, 4K, rating)
  static const TextStyle badge = TextStyle(
    color: KylosColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  // Metadata (duration, genre chips)
  static const TextStyle metadata = TextStyle(
    color: KylosColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

/// Dimensions for dashboard elements.
abstract class KylosDimensions {
  // Top bar
  static const double topBarIconSize = 24.0;
  static const double topBarButtonSize = 44.0;
  static const double logoSize = 40.0;

  // Primary tiles
  static const double tileWidth = 240.0;
  static const double tileHeight = 190.0;
  static const double tileWidthCompact = 180.0;
  static const double tileHeightCompact = 150.0;
  static const double tileIconSize = 64.0;
  static const double tileIconSizeCompact = 52.0;

  // Secondary buttons
  static const double secondaryButtonHeight = 52.0;
  static const double secondaryIconSize = 22.0;
}
