// Kylos IPTV Player - Premium Badge Widget
// Visual indicators for premium features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firebase_providers.dart';

/// A small "PRO" badge to indicate premium features.
///
/// Shows a gold pill-shaped badge that can be placed next to feature labels.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.small,
    this.showIfPro = false,
  });

  /// Size of the badge.
  final PremiumBadgeSize size;

  /// Whether to show the badge even if user is Pro.
  /// By default, the badge hides for Pro users.
  final bool showIfPro;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isPro = ref.watch(hasProProvider);

        // Hide if user is Pro (unless showIfPro is true)
        if (isPro && !showIfPro) {
          return const SizedBox.shrink();
        }

        final (padding, fontSize, iconSize) = switch (size) {
          PremiumBadgeSize.tiny => (
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              9.0,
              10.0,
            ),
          PremiumBadgeSize.small => (
              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              10.0,
              12.0,
            ),
          PremiumBadgeSize.medium => (
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              12.0,
              14.0,
            ),
          PremiumBadgeSize.large => (
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              14.0,
              16.0,
            ),
        };

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              const SizedBox(width: 2),
              Text(
                'PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Size options for PremiumBadge.
enum PremiumBadgeSize {
  tiny,
  small,
  medium,
  large,
}

/// A lock icon overlay for locked premium features.
///
/// Shows a lock icon that can be placed over disabled features.
class LockedFeatureIcon extends StatelessWidget {
  const LockedFeatureIcon({
    super.key,
    this.size = 20,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isPro = ref.watch(hasProProvider);

        // Don't show lock for Pro users
        if (isPro) {
          return const SizedBox.shrink();
        }

        return Icon(
          Icons.lock_rounded,
          size: size,
          color: color ?? KylosColors.textMuted,
        );
      },
    );
  }
}

/// A wrapper that overlays a lock on content for free users.
///
/// Tapping the locked content triggers the onTap callback (typically to show upgrade dialog).
class LockedFeatureOverlay extends StatelessWidget {
  const LockedFeatureOverlay({
    super.key,
    required this.child,
    required this.onTap,
    this.lockSize = 32,
    this.showLockIcon = true,
    this.dimContent = true,
  });

  /// The content to potentially lock.
  final Widget child;

  /// Called when tapping the locked overlay.
  final VoidCallback onTap;

  /// Size of the lock icon.
  final double lockSize;

  /// Whether to show the lock icon.
  final bool showLockIcon;

  /// Whether to dim the content when locked.
  final bool dimContent;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isPro = ref.watch(hasProProvider);

        // If Pro, just show the content
        if (isPro) {
          return this.child;
        }

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              // Content with optional dimming
              if (dimContent)
                Opacity(
                  opacity: 0.5,
                  child: IgnorePointer(child: this.child),
                )
              else
                IgnorePointer(child: this.child),

              // Lock overlay
              if (showLockIcon)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: lockSize,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A list tile suffix that shows PRO badge or lock icon.
///
/// Use in ListTile trailing for premium features.
class PremiumFeatureSuffix extends StatelessWidget {
  const PremiumFeatureSuffix({
    super.key,
    this.showCheckIfUnlocked = false,
  });

  /// Whether to show a checkmark for Pro users.
  final bool showCheckIfUnlocked;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isPro = ref.watch(hasProProvider);

        if (isPro) {
          if (showCheckIfUnlocked) {
            return const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            );
          }
          return const SizedBox.shrink();
        }

        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumBadge(size: PremiumBadgeSize.tiny),
            SizedBox(width: 4),
            LockedFeatureIcon(size: 16),
          ],
        );
      },
    );
  }
}

/// A horizontal row showing "Feature Name" with PRO badge.
///
/// Useful for settings items or feature descriptions.
class PremiumFeatureLabel extends StatelessWidget {
  const PremiumFeatureLabel({
    super.key,
    required this.label,
    this.icon,
    this.labelStyle,
  });

  final String label;
  final IconData? icon;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: KylosColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: labelStyle ?? KylosTvTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const PremiumBadge(size: PremiumBadgeSize.tiny),
      ],
    );
  }
}
