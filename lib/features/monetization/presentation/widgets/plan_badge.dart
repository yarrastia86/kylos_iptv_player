// Kylos IPTV Player - Plan Badge Widget
// Small badge widget showing the user's current subscription plan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_providers.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/screens/paywall_screen.dart';

/// Badge widget displaying the user's current plan.
///
/// Shows "Free" or "Pro" with appropriate styling.
/// Tapping the badge opens the paywall screen.
class PlanBadge extends ConsumerWidget {
  const PlanBadge({
    super.key,
    this.showUpgradeAction = true,
    this.compact = false,
  });

  /// Whether tapping the badge should open the paywall.
  final bool showUpgradeAction;

  /// Whether to show a compact version (icon only for Pro).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(currentEntitlementProvider);
    final hasPro = ref.watch(hasProAccessProvider);

    return _PlanBadgeContent(
      hasPro: hasPro,
      entitlement: entitlement,
      showUpgradeAction: showUpgradeAction,
      compact: compact,
    );
  }
}

class _PlanBadgeContent extends StatelessWidget {
  const _PlanBadgeContent({
    required this.hasPro,
    required this.entitlement,
    required this.showUpgradeAction,
    required this.compact,
  });

  final bool hasPro;
  final Entitlement? entitlement;
  final bool showUpgradeAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (hasPro) {
      return _buildProBadge(context, theme);
    } else {
      return _buildFreeBadge(context, theme);
    }
  }

  Widget _buildProBadge(BuildContext context, ThemeData theme) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: compact ? 14 : 16,
            color: theme.colorScheme.onPrimary,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'PRO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );

    if (showUpgradeAction) {
      return GestureDetector(
        onTap: () => _showPlanDetails(context),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildFreeBadge(BuildContext context, ThemeData theme) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              'FREE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.arrow_upward,
            size: compact ? 14 : 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );

    if (showUpgradeAction) {
      return GestureDetector(
        onTap: () => _openPaywall(context),
        child: badge,
      );
    }

    return badge;
  }

  void _openPaywall(BuildContext context) {
    showPaywall(context);
  }

  void _showPlanDetails(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kylos Pro',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getPlanDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Thank you for supporting Kylos!',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You have access to all premium features.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlanDescription() {
    if (entitlement == null) return 'Active';

    final tier = entitlement!.currentTier;
    switch (tier) {
      case 'pro_monthly':
        return 'Monthly subscription';
      case 'pro_annual':
        return 'Annual subscription';
      case 'pro_lifetime':
        return 'Lifetime access';
      default:
        return 'Active';
    }
  }
}

/// Inline upgrade prompt widget.
///
/// Shows a compact prompt encouraging users to upgrade.
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    this.message,
    this.featureContext,
  });

  /// Custom message to display.
  final String? message;

  /// Context about which feature requires upgrade.
  final String? featureContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.tertiaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ?? 'Upgrade to Pro',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (featureContext != null)
                  Text(
                    featureContext!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => showPaywall(
              context,
              featureContext: featureContext,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

/// Feature lock overlay widget.
///
/// Shows when a feature requires Pro access.
class FeatureLockOverlay extends StatelessWidget {
  const FeatureLockOverlay({
    super.key,
    required this.child,
    required this.isLocked,
    this.featureName,
  });

  /// The child widget to potentially lock.
  final Widget child;

  /// Whether the feature is locked.
  final bool isLocked;

  /// Name of the locked feature (for paywall context).
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    final theme = Theme.of(context);

    return Stack(
      children: [
        // Dimmed child
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(child: child),
        ),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => showPaywall(
              context,
              featureContext: featureName != null
                  ? '$featureName requires Pro access'
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pro Feature',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upgrade',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
