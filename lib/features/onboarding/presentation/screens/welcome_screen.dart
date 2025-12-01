// Kylos IPTV Player - Welcome Screen
// Initial onboarding screen shown to new users.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Welcome screen shown to first-time users.
///
/// This screen introduces the app and guides users to add their first playlist.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo placeholder
              Icon(
                Icons.play_circle_outline,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome to Kylos',
                style:
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'IPTV Player',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Add your IPTV playlist to get started.\n'
                'We support M3U URLs, files, and Xtream Codes API.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Kylos does not provide any IPTV content. '
                  'You must supply your own playlists.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // CTA button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.addPlaylist),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Playlist'),
                ),
              ),
              const SizedBox(height: 12),

              // Skip for later
              TextButton(
                onPressed: () {
                  // TODO: Mark onboarding as skipped, go to main app
                  context.go(Routes.liveTV);
                },
                child: const Text('Skip for now'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
