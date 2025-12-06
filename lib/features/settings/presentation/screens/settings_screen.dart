// Kylos IPTV Player - Settings Screen
// Application settings and preferences with card-based layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/ads/presentation/widgets/banner_ad_widget.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/widgets/premium_badge.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/widgets/upgrade_prompt_dialog.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/settings/domain/app_settings.dart';
import 'package:kylos_iptv_player/features/settings/presentation/providers/settings_providers.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firebase_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Settings screen with card-based layout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsState = ref.watch(playlistsNotifierProvider);
    final isPro = ref.watch(hasProProvider);

    return ScreenWithBannerAd(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Section
              _SectionHeader(title: 'Subscription'),
              const SizedBox(height: 12),
              _SubscriptionCard(isPro: isPro),
              const SizedBox(height: 24),

              // Playlists Section
              _SectionHeader(title: 'Playlists'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsCardItem(
                    icon: Icons.playlist_play,
                    iconColor: theme.colorScheme.primary,
                    title: 'Manage Playlists',
                    subtitle: '${playlistsState.playlists.length} playlist(s) configured',
                    onTap: () => context.push(Routes.playlists),
                  ),
                  const Divider(height: 1),
                  _SettingsCardItem(
                    icon: Icons.add_circle_outline,
                    iconColor: Colors.green,
                    title: 'Add New Playlist',
                    subtitle: 'M3U URL or Xtream Codes',
                    onTap: () => context.push(Routes.addPlaylistFromSettings),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Playback Section
              _SectionHeader(title: 'Playback'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _VideoQualityItem(ref: ref),
                  const Divider(height: 1),
                  _BufferSizeItem(ref: ref),
                  const Divider(height: 1),
                  _AutoPlayItem(ref: ref),
                ],
              ),
              const SizedBox(height: 24),

              // Premium Features Section
              _SectionHeader(title: 'Premium Features'),
              const SizedBox(height: 12),
              _PremiumFeaturesCard(isPro: isPro),
              const SizedBox(height: 24),

              // Appearance Section
              _SectionHeader(title: 'Appearance'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _ThemeItem(ref: ref),
                ],
              ),
              const SizedBox(height: 24),

              // About Section
              _SectionHeader(title: 'About'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsCardItem(
                    icon: Icons.info_outline,
                    iconColor: theme.colorScheme.secondary,
                    title: 'About Kylos IPTV',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kylos IPTV Player',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.live_tv, size: 48),
      children: [
        const Text('A modern IPTV player for streaming live TV, movies, and series.'),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsCardItem extends StatelessWidget {
  const _SettingsCardItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// Video Quality Setting with dropdown
class _VideoQualityItem extends ConsumerWidget {
  const _VideoQualityItem({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.hd, color: Colors.blue, size: 24),
      ),
      title: const Text('Video Quality'),
      subtitle: Text(
        settings.videoQuality.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<VideoQuality>(
        value: settings.videoQuality,
        underline: const SizedBox(),
        items: VideoQuality.values.map((quality) {
          return DropdownMenuItem(
            value: quality,
            child: Text(quality.displayName),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            notifier.setVideoQuality(value);
          }
        },
      ),
    );
  }
}

// Buffer Size Setting
class _BufferSizeItem extends ConsumerWidget {
  const _BufferSizeItem({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.speed, color: Colors.orange, size: 24),
      ),
      title: const Text('Buffer Size'),
      subtitle: Text(
        settings.bufferSize.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<BufferSize>(
        value: settings.bufferSize,
        underline: const SizedBox(),
        items: BufferSize.values.map((size) {
          return DropdownMenuItem(
            value: size,
            child: Text(size.displayName),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            notifier.setBufferSize(value);
          }
        },
      ),
    );
  }
}

// Auto Play Setting
class _AutoPlayItem extends ConsumerWidget {
  const _AutoPlayItem({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle_outline, color: Colors.green, size: 24),
      ),
      title: const Text('Auto Play'),
      subtitle: Text(settings.autoPlay ? 'Enabled' : 'Disabled'),
      trailing: Switch(
        value: settings.autoPlay,
        onChanged: (value) {
          notifier.setAutoPlay(value);
        },
      ),
    );
  }
}

// Theme Setting
class _ThemeItem extends ConsumerWidget {
  const _ThemeItem({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.palette, color: Colors.purple, size: 24),
      ),
      title: const Text('Theme'),
      subtitle: Text(
        settings.themeMode.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<AppThemeMode>(
        value: settings.themeMode,
        underline: const SizedBox(),
        items: AppThemeMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(mode.displayName),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            notifier.setThemeMode(value);
          }
        },
      ),
    );
  }
}

/// Subscription status card showing current tier and upgrade option.
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPro) {
      // Pro user card
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.1),
                const Color(0xFFFFA500).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            ),
            title: Row(
              children: [
                const Text('Kylos Pro'),
                const SizedBox(width: 8),
                const PremiumBadge(size: PremiumBadgeSize.small, showIfPro: true),
              ],
            ),
            subtitle: Text(
              'You have access to all premium features',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      );
    }

    // Free user card with upgrade CTA
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
            ),
            title: const Text('Free Plan'),
            subtitle: Text(
              'Upgrade to unlock all features',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => context.push(Routes.paywall),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.1),
                    const Color(0xFFFFA500).withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Pro',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'No ads, unlimited playlists, cloud sync & more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium features card showing what's included with Pro.
class _PremiumFeaturesCard extends StatelessWidget {
  const _PremiumFeaturesCard({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Ad-Free Experience
          _PremiumFeatureItem(
            icon: Icons.block,
            iconColor: Colors.red,
            title: 'Ad-Free Experience',
            subtitle: isPro ? 'Enabled' : 'Upgrade to remove all ads',
            isUnlocked: isPro,
            onTap: isPro
                ? null
                : () => UpgradePromptDialog.show(
                      context,
                      featureName: 'Ad-Free Experience',
                      featureDescription:
                          'Remove all ads from the app for a seamless viewing experience.',
                      featureIcon: Icons.block,
                    ),
          ),
          const Divider(height: 1),
          // Unlimited Playlists
          _PremiumFeatureItem(
            icon: Icons.playlist_add,
            iconColor: Colors.blue,
            title: 'Unlimited Playlists',
            subtitle: isPro ? 'Up to 10 playlists' : 'Free: 1 playlist',
            isUnlocked: isPro,
            onTap: isPro
                ? null
                : () => UpgradePromptDialog.show(
                      context,
                      featureName: 'Unlimited Playlists',
                      featureDescription:
                          'Add up to 10 different playlists and switch between them easily.',
                      featureIcon: Icons.playlist_add,
                    ),
          ),
          const Divider(height: 1),
          // Cloud Sync
          _PremiumFeatureItem(
            icon: Icons.cloud_sync,
            iconColor: Colors.cyan,
            title: 'Cloud Sync',
            subtitle: isPro ? 'Sync across devices' : 'Local storage only',
            isUnlocked: isPro,
            onTap: isPro
                ? null
                : () => UpgradePromptDialog.show(
                      context,
                      featureName: 'Cloud Sync',
                      featureDescription:
                          'Sync your playlists, favorites, and watch history across all your devices.',
                      featureIcon: Icons.cloud_sync,
                    ),
          ),
          const Divider(height: 1),
          // Extended EPG
          _PremiumFeatureItem(
            icon: Icons.calendar_today,
            iconColor: Colors.purple,
            title: 'Extended EPG Guide',
            subtitle: isPro ? '7-day guide' : 'Free: 1-day guide',
            isUnlocked: isPro,
            onTap: isPro
                ? null
                : () => UpgradePromptDialog.show(
                      context,
                      featureName: 'Extended EPG Guide',
                      featureDescription:
                          'View the TV guide for up to 7 days ahead to plan your viewing.',
                      featureIcon: Icons.calendar_today,
                    ),
          ),
          const Divider(height: 1),
          // Multiple Profiles
          _PremiumFeatureItem(
            icon: Icons.people,
            iconColor: Colors.orange,
            title: 'Multiple Profiles',
            subtitle: isPro ? 'Up to 10 profiles' : 'Free: 2 profiles',
            isUnlocked: isPro,
            onTap: isPro
                ? null
                : () => UpgradePromptDialog.show(
                      context,
                      featureName: 'Multiple Profiles',
                      featureDescription:
                          'Create up to 10 profiles for family members with separate favorites and watch history.',
                      featureIcon: Icons.people,
                    ),
          ),
        ],
      ),
    );
  }
}

/// Individual premium feature item.
class _PremiumFeatureItem extends StatelessWidget {
  const _PremiumFeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Row(
        children: [
          Text(title),
          if (!isUnlocked) ...[
            const SizedBox(width: 8),
            const PremiumBadge(size: PremiumBadgeSize.tiny),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isUnlocked
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : const LockedFeatureIcon(size: 20),
    );
  }
}
