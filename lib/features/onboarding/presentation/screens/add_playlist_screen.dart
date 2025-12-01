// Kylos IPTV Player - Add Playlist Screen
// Screen for adding a new IPTV playlist source.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/playlist_url.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen for adding a new IPTV playlist.
///
/// Supports three types of playlist sources:
/// - M3U URL: Direct link to an M3U playlist
/// - M3U File: Local file upload
/// - Xtream Codes: Server URL with username/password
class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  PlaylistType _selectedType = PlaylistType.m3uUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Playlist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Playlist name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  hintText: 'My IPTV Provider',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Playlist type selector
              Text(
                'Playlist Type',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PlaylistType>(
                segments: const [
                  ButtonSegment(
                    value: PlaylistType.m3uUrl,
                    label: Text('M3U URL'),
                    icon: Icon(Icons.link),
                  ),
                  ButtonSegment(
                    value: PlaylistType.m3uFile,
                    label: Text('File'),
                    icon: Icon(Icons.file_upload),
                  ),
                  ButtonSegment(
                    value: PlaylistType.xtream,
                    label: Text('Xtream'),
                    icon: Icon(Icons.api),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() => _selectedType = selection.first);
                },
              ),
              const SizedBox(height: 24),

              // Type-specific input fields
              ..._buildTypeSpecificFields(),

              const SizedBox(height: 32),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _onSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Playlist'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_selectedType) {
      case PlaylistType.m3uUrl:
        return [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Playlist URL',
              hintText: 'https://example.com/playlist.m3u',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a URL';
              }
              if (!Uri.tryParse(value)!.hasScheme ?? true) {
                return 'Please enter a valid URL';
              }
              return null;
            },
          ),
        ];

      case PlaylistType.m3uFile:
        return [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement file picker
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('Select M3U File'),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported formats: .m3u, .m3u8',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ];

      case PlaylistType.xtream:
        return [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://provider.example.com:8080',
              prefixIcon: Icon(Icons.dns),
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the server URL';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
        ];
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create the playlist based on type
      PlaylistSource? playlist;

      switch (_selectedType) {
        case PlaylistType.m3uUrl:
          final url = PlaylistUrl.tryParse(_urlController.text);
          if (url == null) {
            throw Exception('Invalid URL');
          }
          playlist = PlaylistSource.m3uUrl(
            name: _nameController.text.trim(),
            url: url,
          );

        case PlaylistType.m3uFile:
          // File picker not yet implemented
          throw Exception('File upload not yet implemented');

        case PlaylistType.xtream:
          final credentials = XtreamCredentials.tryCreate(
            serverUrl: _urlController.text,
            username: _usernameController.text,
            password: _passwordController.text,
          );
          if (credentials == null) {
            throw Exception('Invalid Xtream credentials');
          }
          playlist = PlaylistSource.xtream(
            name: _nameController.text.trim(),
            credentials: credentials,
          );
      }

      // Save the playlist via the notifier
      final success = await ref
          .read(playlistsNotifierProvider.notifier)
          .addPlaylist(playlist);

      if (!success) {
        final error = ref.read(playlistsNotifierProvider).error;
        throw Exception(error ?? 'Failed to add playlist');
      }

      // Set as active playlist
      await ref
          .read(activePlaylistNotifierProvider.notifier)
          .setActivePlaylist(playlist);

      if (mounted) {
        // Navigate to main app after successful addition
        context.go(Routes.liveTV);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add playlist: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
