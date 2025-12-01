// Kylos IPTV Player - Playlists Management Screen
// Screen for managing IPTV playlist sources.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for managing playlist sources.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsState = ref.watch(playlistsNotifierProvider);
    final activePlaylist = ref.watch(activePlaylistProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Playlist',
            onPressed: () => context.push(Routes.addPlaylist),
          ),
        ],
      ),
      body: playlistsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistsState.playlists.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: playlistsState.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistsState.playlists[index];
                    final isActive = activePlaylist?.id == playlist.id;

                    return _PlaylistCard(
                      playlist: playlist,
                      isActive: isActive,
                      onTap: () => _showPlaylistOptions(context, ref, playlist, isActive),
                      onSetActive: () => _setActivePlaylist(ref, playlist),
                      onDelete: () => _confirmDelete(context, ref, playlist),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addPlaylist),
        icon: const Icon(Icons.add),
        label: const Text('Add Playlist'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No playlists configured',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first playlist to start watching',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(Routes.addPlaylist),
            icon: const Icon(Icons.add),
            label: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
    BuildContext context,
    WidgetRef ref,
    PlaylistSource playlist,
    bool isActive,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Set as Active'),
                subtitle: isActive ? const Text('Currently active') : null,
                enabled: !isActive,
                onTap: () {
                  Navigator.pop(context);
                  _setActivePlaylist(ref, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh Playlist'),
                subtitle: const Text('Re-fetch channels from source'),
                onTap: () {
                  Navigator.pop(context);
                  _refreshPlaylist(context, ref, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistDetails(context, playlist);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Delete Playlist',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, playlist);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _setActivePlaylist(WidgetRef ref, PlaylistSource playlist) {
    ref.read(activePlaylistNotifierProvider.notifier).setActivePlaylist(playlist);
  }

  void _refreshPlaylist(BuildContext context, WidgetRef ref, PlaylistSource playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing ${playlist.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // The channel repository will refresh when channels are loaded
  }

  void _showPlaylistDetails(BuildContext context, PlaylistSource playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(playlist.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: _getTypeLabel(playlist.type)),
            if (playlist.url != null)
              _DetailRow(label: 'URL', value: playlist.url!.value),
            if (playlist.xtreamCredentials != null) ...[
              _DetailRow(
                label: 'Server',
                value: playlist.xtreamCredentials!.serverUrl.value,
              ),
              _DetailRow(
                label: 'Username',
                value: playlist.xtreamCredentials!.username,
              ),
            ],
            if (playlist.createdAt != null)
              _DetailRow(
                label: 'Added',
                value: _formatDate(playlist.createdAt!),
              ),
            if (playlist.lastRefresh != null)
              _DetailRow(
                label: 'Last Refreshed',
                value: _formatDate(playlist.lastRefresh!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PlaylistSource playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(playlistsNotifierProvider.notifier).removePlaylist(playlist.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${playlist.name} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(PlaylistType type) {
    switch (type) {
      case PlaylistType.m3uUrl:
        return 'M3U URL';
      case PlaylistType.m3uFile:
        return 'M3U File';
      case PlaylistType.xtream:
        return 'Xtream Codes';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.isActive,
    required this.onTap,
    required this.onSetActive,
    required this.onDelete,
  });

  final PlaylistSource playlist;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSetActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(playlist.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(playlist.type),
                  color: _getTypeColor(playlist.type),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            playlist.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeLabel(playlist.type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(PlaylistType type) {
    switch (type) {
      case PlaylistType.m3uUrl:
        return Icons.link;
      case PlaylistType.m3uFile:
        return Icons.insert_drive_file;
      case PlaylistType.xtream:
        return Icons.api;
    }
  }

  Color _getTypeColor(PlaylistType type) {
    switch (type) {
      case PlaylistType.m3uUrl:
        return Colors.blue;
      case PlaylistType.m3uFile:
        return Colors.orange;
      case PlaylistType.xtream:
        return Colors.purple;
    }
  }

  String _getTypeLabel(PlaylistType type) {
    switch (type) {
      case PlaylistType.m3uUrl:
        return 'M3U URL';
      case PlaylistType.m3uFile:
        return 'M3U File';
      case PlaylistType.xtream:
        return 'Xtream Codes';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
