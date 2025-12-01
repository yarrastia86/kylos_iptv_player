// Kylos IPTV Player - Settings Screen
// Application settings and preferences with card-based layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
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
                  onTap: () => context.push(Routes.addPlaylist),
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
class _VideoQualityItem extends ConsumerStatefulWidget {
  const _VideoQualityItem({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_VideoQualityItem> createState() => _VideoQualityItemState();
}

class _VideoQualityItemState extends ConsumerState<_VideoQualityItem> {
  String _selectedQuality = 'Auto';
  final List<String> _qualities = ['Auto', '1080p', '720p', '480p', '360p'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        _selectedQuality,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<String>(
        value: _selectedQuality,
        underline: const SizedBox(),
        items: _qualities.map((quality) {
          return DropdownMenuItem(value: quality, child: Text(quality));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedQuality = value);
            // TODO: Save to preferences
          }
        },
      ),
    );
  }
}

// Buffer Size Setting
class _BufferSizeItem extends ConsumerStatefulWidget {
  const _BufferSizeItem({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_BufferSizeItem> createState() => _BufferSizeItemState();
}

class _BufferSizeItemState extends ConsumerState<_BufferSizeItem> {
  String _selectedBuffer = 'Normal';
  final List<String> _bufferSizes = ['Low', 'Normal', 'High'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        _selectedBuffer,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<String>(
        value: _selectedBuffer,
        underline: const SizedBox(),
        items: _bufferSizes.map((size) {
          return DropdownMenuItem(value: size, child: Text(size));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedBuffer = value);
            // TODO: Save to preferences
          }
        },
      ),
    );
  }
}

// Auto Play Setting
class _AutoPlayItem extends ConsumerStatefulWidget {
  const _AutoPlayItem({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_AutoPlayItem> createState() => _AutoPlayItemState();
}

class _AutoPlayItemState extends ConsumerState<_AutoPlayItem> {
  bool _autoPlay = true;

  @override
  Widget build(BuildContext context) {
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
      subtitle: Text(_autoPlay ? 'Enabled' : 'Disabled'),
      trailing: Switch(
        value: _autoPlay,
        onChanged: (value) {
          setState(() => _autoPlay = value);
          // TODO: Save to preferences
        },
      ),
    );
  }
}

// Theme Setting
class _ThemeItem extends ConsumerStatefulWidget {
  const _ThemeItem({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_ThemeItem> createState() => _ThemeItemState();
}

class _ThemeItemState extends ConsumerState<_ThemeItem> {
  String _selectedTheme = 'Dark';
  final List<String> _themes = ['System', 'Light', 'Dark'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        _selectedTheme,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        underline: const SizedBox(),
        items: _themes.map((t) {
          return DropdownMenuItem(value: t, child: Text(t));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTheme = value);
            // TODO: Apply theme change
          }
        },
      ),
    );
  }
}
