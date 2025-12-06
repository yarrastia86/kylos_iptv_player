// Kylos IPTV Player - Upgrade Prompt Dialog
// Dialog shown when users try to access premium features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// A dialog that prompts users to upgrade to Pro when accessing locked features.
///
/// Shows the feature name, description, and CTAs to upgrade or dismiss.
class UpgradePromptDialog extends ConsumerWidget {
  const UpgradePromptDialog({
    super.key,
    required this.featureName,
    this.featureDescription,
    this.featureIcon,
    this.benefits,
  });

  /// Name of the locked feature.
  final String featureName;

  /// Optional description of what the feature does.
  final String? featureDescription;

  /// Optional icon for the feature.
  final IconData? featureIcon;

  /// Optional list of benefits for upgrading.
  final List<String>? benefits;

  /// Show the dialog and return true if user chose to upgrade.
  static Future<bool> show(
    BuildContext context, {
    required String featureName,
    String? featureDescription,
    IconData? featureIcon,
    List<String>? benefits,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UpgradePromptDialog(
        featureName: featureName,
        featureDescription: featureDescription,
        featureIcon: featureIcon,
        benefits: benefits,
      ),
    );
    return result ?? false;
  }

  void _handleUpgrade(BuildContext context) {
    Navigator.of(context).pop(true);
    context.push(Routes.paywall);
  }

  void _handleDismiss(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultBenefits = benefits ??
        [
          'Unlimited playlists',
          'Cloud sync across devices',
          '7-day EPG guide',
          'Ad-free experience',
        ];

    return Dialog(
      backgroundColor: KylosColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KylosRadius.l),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(KylosSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.2),
                      const Color(0xFFFFA500).withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  featureIcon ?? Icons.lock_rounded,
                  size: 48,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: KylosSpacing.l),

              // Title
              Text(
                'Unlock $featureName',
                style: KylosTvTextStyles.sectionHeader.copyWith(
                  color: KylosColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.s),

              // Description
              Text(
                featureDescription ?? 'This feature is available with Kylos Pro',
                style: KylosTvTextStyles.body.copyWith(
                  color: KylosColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.l),

              // Benefits list
              Container(
                padding: const EdgeInsets.all(KylosSpacing.m),
                decoration: BoxDecoration(
                  color: KylosColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(KylosRadius.m),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro includes:',
                      style: KylosTvTextStyles.cardSubtitle.copyWith(
                        color: KylosColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: KylosSpacing.s),
                    ...defaultBenefits.map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: KylosTvTextStyles.body.copyWith(
                                    color: KylosColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: KylosSpacing.xl),

              // Buttons
              Row(
                children: [
                  // Dismiss button
                  Expanded(
                    child: TextButton(
                      onPressed: () => _handleDismiss(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: KylosTvTextStyles.button.copyWith(
                          color: KylosColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KylosSpacing.m),
                  // Upgrade button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _handleUpgrade(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KylosRadius.m),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Upgrade to Pro',
                            style: KylosTvTextStyles.button.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// A simpler inline upgrade prompt for use in lists/cards.
class InlineUpgradePrompt extends StatelessWidget {
  const InlineUpgradePrompt({
    super.key,
    this.message = 'Upgrade to Pro to unlock this feature',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: () => context.push(Routes.paywall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'Upgrade',
                style: KylosTvTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push(Routes.paywall),
      child: Container(
        padding: const EdgeInsets.all(KylosSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.1),
              const Color(0xFFFFA500).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(KylosRadius.m),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: KylosSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: KylosTvTextStyles.body.copyWith(
                      color: KylosColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tap to see plans',
                    style: KylosTvTextStyles.cardSubtitle.copyWith(
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFFFD700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to check feature access and show upgrade prompt if needed.
///
/// Returns true if user has access (is Pro), false if they dismissed the prompt.
Future<bool> checkFeatureAccessOrPrompt(
  BuildContext context,
  WidgetRef ref, {
  required bool hasAccess,
  required String featureName,
  String? featureDescription,
  IconData? featureIcon,
}) async {
  if (hasAccess) {
    return true;
  }

  return UpgradePromptDialog.show(
    context,
    featureName: featureName,
    featureDescription: featureDescription,
    featureIcon: featureIcon,
  );
}
