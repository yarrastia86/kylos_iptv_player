// Kylos IPTV Player - Profile Selection Screen
// Screen for selecting or managing user profiles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile selection screen.
///
/// Displayed when the app launches (after onboarding) to let
/// users select which profile to use.
class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect to profiles provider
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who is watching?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Toggle edit mode
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Default profile
            _ProfileAvatar(
              name: 'Default',
              isSelected: true,
              onTap: () {
                // TODO: Select profile and navigate
              },
            ),
            const SizedBox(height: 32),

            // Add profile button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to add profile
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar widget for profile selection.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    this.avatarUrl,
    this.isSelected = false,
    this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
