// Kylos IPTV Player - App Colors
// Color palette for the application design system.

import 'package:flutter/material.dart';

/// Application color palette following Material 3 guidelines.
abstract class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary colors
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary colors
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Colors.white;

  // Error colors
  static const Color error = Color(0xFFF2B8B5);
  static const Color onError = Color(0xFF601410);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Colors.white;
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color dividerDark = Color(0xFF3D3D3D);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFFFFBFE);
  static const Color surfaceLight = Color(0xFFFFFBFE);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);
  static const Color cardLight = Color(0xFFF5F5F5);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Playback colors
  static const Color live = Color(0xFFE53935);
  static const Color buffering = Color(0xFFFF9800);

  // Focus colors (for TV)
  static const Color focusBorder = Color(0xFF6750A4);
  static const Color focusGlow = Color(0x406750A4);
}
