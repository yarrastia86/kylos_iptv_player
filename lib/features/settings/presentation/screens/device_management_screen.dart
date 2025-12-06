// Kylos IPTV Player - Device Management Screen
// UI for managing registered devices and active streams.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/devices/device_providers.dart';
import 'package:kylos_iptv_player/core/devices/stream_session.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// Screen for managing devices and viewing active streams.
class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Register current device on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerCurrentDevice();
    });
  }

  Future<void> _registerCurrentDevice() async {
    final result =
        await ref.read(deviceManagerProvider.notifier).registerCurrentDevice();

    if (result is DeviceRegistrationLimitExceeded && mounted) {
      _showDeviceLimitDialog(result);
    }
  }

  void _showDeviceLimitDialog(DeviceRegistrationLimitExceeded result) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Device Limit Reached',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have reached the maximum of ${result.maxDevices} devices for your subscription.',
              style: const TextStyle(color: KylosColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Remove a device to add this one, or upgrade your plan for more devices.',
              style: TextStyle(color: KylosColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to paywall
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KylosColors.tvAccent,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(userDevicesProvider);
    final activeSessionsAsync = ref.watch(activeSessionsProvider);
    final maxDevices = ref.watch(maxRegisteredDevicesProvider);
    final maxStreams = ref.watch(maxConcurrentStreamsProvider);

    return Scaffold(
      backgroundColor: KylosColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text('Manage Devices'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KylosSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Streams Section
            _buildSectionHeader(
              'Active Streams',
              subtitle: activeSessionsAsync.when(
                data: (sessions) => '${sessions.length}/$maxStreams screens',
                loading: () => 'Loading...',
                error: (_, __) => 'Error',
              ),
              icon: Icons.play_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(height: KylosSpacing.s),
            activeSessionsAsync.when(
              data: (sessions) => _buildActiveSessionsList(sessions),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),

            const SizedBox(height: KylosSpacing.xl),

            // Registered Devices Section
            _buildSectionHeader(
              'Registered Devices',
              subtitle: devicesAsync.when(
                data: (devices) => '${devices.length}/$maxDevices devices',
                loading: () => 'Loading...',
                error: (_, __) => 'Error',
              ),
              icon: Icons.devices,
              color: KylosColors.tvAccent,
            ),
            const SizedBox(height: KylosSpacing.s),
            devicesAsync.when(
              data: (devices) => _buildDevicesList(devices),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),

            const SizedBox(height: KylosSpacing.xl),

            // Plan Info
            _buildPlanInfo(maxStreams, maxDevices),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: KylosSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KylosTvTextStyles.sectionHeader.copyWith(
                  color: KylosColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: KylosTvTextStyles.body.copyWith(
                  color: KylosColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionsList(List<StreamSession> sessions) {
    if (sessions.isEmpty) {
      return const _EmptyCard(
        message: 'No active streams',
        icon: Icons.tv_off,
      );
    }

    return Column(
      children: sessions.map((session) {
        return _ActiveSessionCard(
          session: session,
          onTerminate: () => _terminateSession(session),
        );
      }).toList(),
    );
  }

  Widget _buildDevicesList(List<Device> devices) {
    if (devices.isEmpty) {
      return const _EmptyCard(
        message: 'No devices registered',
        icon: Icons.devices,
      );
    }

    return Column(
      children: devices.map((device) {
        return _DeviceCard(
          device: device,
          onRename: () => _renameDevice(device),
          onRemove: () => _removeDevice(device),
        );
      }).toList(),
    );
  }

  Widget _buildPlanInfo(int maxStreams, int maxDevices) {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: Border.all(color: KylosColors.tvAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: KylosColors.tvAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Plan',
                style: KylosTvTextStyles.cardTitle.copyWith(
                  color: KylosColors.tvAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: KylosSpacing.s),
          _buildPlanRow(Icons.tv, '$maxStreams screens at a time'),
          _buildPlanRow(Icons.devices, 'Up to $maxDevices devices'),
          const SizedBox(height: KylosSpacing.m),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to paywall for upgrade
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: KylosColors.tvAccent,
                side: const BorderSide(color: KylosColors.tvAccent),
              ),
              child: const Text('Upgrade Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KylosColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: KylosTvTextStyles.body.copyWith(
              color: KylosColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _terminateSession(StreamSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'End Stream?',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Text(
          'This will stop playback on ${session.deviceName}.',
          style: const TextStyle(color: KylosColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(streamSessionManagerProvider.notifier)
          .terminateSession(session.id);
    }
  }

  Future<void> _renameDevice(Device device) async {
    final controller = TextEditingController(text: device.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Rename Device',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: KylosColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Device name',
            hintStyle: TextStyle(color: KylosColors.textMuted),
            filled: true,
            fillColor: KylosColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: KylosColors.tvAccent,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref
          .read(deviceManagerProvider.notifier)
          .renameDevice(device.id, newName);
    }
  }

  Future<void> _removeDevice(Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Remove Device?',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: Text(
          'Remove "${device.name}" from your account? You can add it again later.',
          style: const TextStyle(color: KylosColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(deviceManagerProvider.notifier).removeDevice(device.id);
    }
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.onTerminate,
  });

  final StreamSession session;
  final VoidCallback onTerminate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KylosSpacing.s),
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: Border.all(
          color: session.isActive
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.isActive ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: KylosSpacing.m),

          // Device icon
          Icon(
            _getDeviceIcon(session.devicePlatform),
            color: KylosColors.textSecondary,
            size: 32,
          ),
          const SizedBox(width: KylosSpacing.m),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName,
                  style: KylosTvTextStyles.cardTitle.copyWith(
                    color: KylosColors.textPrimary,
                  ),
                ),
                if (session.contentTitle != null)
                  Text(
                    session.contentTitle!,
                    style: KylosTvTextStyles.cardSubtitle.copyWith(
                      color: KylosColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  session.isActive ? 'Streaming now' : 'Paused',
                  style: KylosTvTextStyles.body.copyWith(
                    color:
                        session.isActive ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Terminate button
          IconButton(
            onPressed: onTerminate,
            icon: const Icon(Icons.close),
            color: Colors.red,
            tooltip: 'End stream',
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
      case DevicePlatform.androidTv:
      case DevicePlatform.androidAuto:
        return Icons.android;
      case DevicePlatform.ios:
      case DevicePlatform.macos:
      case DevicePlatform.appleTv:
      case DevicePlatform.carPlay:
        return Icons.apple;
      case DevicePlatform.windows:
        return Icons.desktop_windows;
      case DevicePlatform.linux:
        return Icons.computer;
      case DevicePlatform.fireTv:
        return Icons.tv;
      case DevicePlatform.roku:
        return Icons.tv;
      case DevicePlatform.web:
        return Icons.public;
      case DevicePlatform.unknown:
        return Icons.devices;
    }
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.onRename,
    required this.onRemove,
  });

  final Device device;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KylosSpacing.s),
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: device.isCurrentDevice
            ? Border.all(color: KylosColors.tvAccent.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          // Device icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KylosColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getDeviceIcon(device.platform),
              color: device.isCurrentDevice
                  ? KylosColors.tvAccent
                  : KylosColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: KylosSpacing.m),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: KylosTvTextStyles.cardTitle.copyWith(
                        color: KylosColors.textPrimary,
                      ),
                    ),
                    if (device.isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KylosColors.tvAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'This device',
                          style: TextStyle(
                            color: KylosColors.tvAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  device.shortDescription,
                  style: KylosTvTextStyles.cardSubtitle.copyWith(
                    color: KylosColors.textSecondary,
                  ),
                ),
                if (device.model != null)
                  Text(
                    device.model!,
                    style: KylosTvTextStyles.body.copyWith(
                      color: KylosColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: KylosColors.textSecondary),
            color: KylosColors.surfaceLight,
            onSelected: (value) {
              if (value == 'rename') {
                onRename();
              } else if (value == 'remove') {
                onRemove();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              if (!device.isCurrentDevice)
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.xl),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.m),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: KylosColors.tvAccent),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.xl),
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.m),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: KylosColors.textMuted),
            const SizedBox(height: KylosSpacing.s),
            Text(
              message,
              style: KylosTvTextStyles.body.copyWith(
                color: KylosColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KylosRadius.m),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: KylosSpacing.s),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
