// Kylos IPTV Player - Stream Limit Dialog
// Dialog shown when concurrent stream limit is exceeded.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_providers.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// Dialog showing when user exceeds their concurrent stream limit.
///
/// Provides options to:
/// - End one of the active streams
/// - Upgrade to a higher plan
/// - Cancel and go back
class StreamLimitDialog extends ConsumerWidget {
  const StreamLimitDialog({
    super.key,
    required this.maxStreams,
    required this.activeSessions,
  });

  final int maxStreams;
  final List<StreamSession> activeSessions;

  /// Shows the stream limit dialog.
  ///
  /// Returns true if a session was terminated and stream can proceed,
  /// false if user cancelled or chose to upgrade.
  static Future<bool> show(
    BuildContext context, {
    required int maxStreams,
    required List<StreamSession> activeSessions,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamLimitDialog(
        maxStreams: maxStreams,
        activeSessions: activeSessions,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: KylosColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KylosRadius.l),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(KylosSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: KylosSpacing.l),

              // Title
              Text(
                'Too Many Streams',
                style: KylosTvTextStyles.sectionHeader.copyWith(
                  color: KylosColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.s),

              // Description
              Text(
                'Your plan allows $maxStreams ${maxStreams == 1 ? 'screen' : 'screens'} at a time.\n'
                'Choose a stream to end, or upgrade for more screens.',
                style: KylosTvTextStyles.body.copyWith(
                  color: KylosColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.l),

              // Active sessions list
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeSessions.length,
                  itemBuilder: (context, index) {
                    final session = activeSessions[index];
                    return _SessionTile(
                      session: session,
                      onEnd: () async {
                        await ref
                            .read(streamSessionManagerProvider.notifier)
                            .terminateSession(session.id);
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: KylosSpacing.l),

              // Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: KylosTvTextStyles.button.copyWith(
                          color: KylosColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KylosSpacing.m),
                  // Upgrade
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        // Navigate to paywall
                        // TODO: Add navigation
                      },
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('Upgrade Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KylosColors.tvAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KylosRadius.m),
                        ),
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

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onEnd,
  });

  final StreamSession session;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KylosSpacing.s),
      padding: const EdgeInsets.all(KylosSpacing.s),
      decoration: BoxDecoration(
        color: KylosColors.surfaceLight,
        borderRadius: BorderRadius.circular(KylosRadius.s),
      ),
      child: Row(
        children: [
          // Device icon
          Icon(
            _getDeviceIcon(session.devicePlatform),
            color: KylosColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: KylosSpacing.s),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.deviceName,
                  style: KylosTvTextStyles.cardTitle.copyWith(
                    color: KylosColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (session.contentTitle != null)
                  Text(
                    session.contentTitle!,
                    style: KylosTvTextStyles.cardSubtitle.copyWith(
                      color: KylosColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // End button
          TextButton(
            onPressed: onEnd,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return Icons.phone_android;
      case DevicePlatform.ios:
        return Icons.phone_iphone;
      case DevicePlatform.macos:
      case DevicePlatform.windows:
      case DevicePlatform.linux:
        return Icons.laptop;
      case DevicePlatform.androidTv:
      case DevicePlatform.fireTv:
      case DevicePlatform.appleTv:
      case DevicePlatform.roku:
        return Icons.tv;
      case DevicePlatform.androidAuto:
      case DevicePlatform.carPlay:
        return Icons.directions_car;
      case DevicePlatform.web:
        return Icons.public;
      case DevicePlatform.unknown:
        return Icons.devices;
    }
  }
}

/// Widget shown on the player screen when stream limit is reached.
class StreamLimitOverlay extends StatelessWidget {
  const StreamLimitOverlay({
    super.key,
    required this.maxStreams,
    required this.onManageDevices,
    required this.onUpgrade,
    required this.onBack,
  });

  final int maxStreams;
  final VoidCallback onManageDevices;
  final VoidCallback onUpgrade;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KylosSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: KylosSpacing.xl),

              // Title
              Text(
                'Screen Limit Reached',
                style: KylosTvTextStyles.sectionHeader.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.m),

              // Description
              Text(
                'Your plan allows watching on $maxStreams ${maxStreams == 1 ? 'device' : 'devices'} at a time.\n\n'
                'To watch here, stop watching on another device, '
                'or upgrade your plan for more screens.',
                style: KylosTvTextStyles.body.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.xxl),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Manage devices
                  OutlinedButton.icon(
                    onPressed: onManageDevices,
                    icon: const Icon(Icons.devices),
                    label: const Text('Manage Devices'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: KylosSpacing.m),
                  // Upgrade
                  ElevatedButton.icon(
                    onPressed: onUpgrade,
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Upgrade Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KylosColors.tvAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KylosSpacing.xl),

              // Back button
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
