// Kylos IPTV Player - Settings Screen
// Application settings and preferences with card-based layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/features/settings/domain/app_settings.dart';
import 'package:kylos_iptv_player/features/settings/presentation/providers/settings_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Settings screen with card-based layout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsState = ref.watch(playlistsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
