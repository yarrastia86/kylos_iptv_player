// Kylos IPTV Player - Available Device Tile
// Displays a single device available for handoff.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/core/devices/device.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/device_presence.dart';

/// Widget displaying a device available for handoff.
class AvailableDeviceTile extends StatelessWidget {
  const AvailableDeviceTile({
    required this.device,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.isLoading = false,
  });

  final DevicePresence device;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Colors.amber.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceName(),
                    const SizedBox(height: 4),
                    _buildDeviceInfo(),
                    if (device.isPlaying) ...[
                      const SizedBox(height: 6),
                      _buildCurrentPlayback(),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.amber),
                  ),
                )
              else
                const Icon(
                  Icons.cast,
                  color: Colors.white54,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getDeviceIcon(),
        color: Colors.amber,
        size: 24,
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (device.formFactor) {
      case DeviceFormFactor.tv:
        return Icons.tv;
      case DeviceFormFactor.tablet:
        return Icons.tablet_android;
      case DeviceFormFactor.phone:
        return Icons.phone_android;
      case DeviceFormFactor.desktop:
        return Icons.computer;
      case DeviceFormFactor.web:
        return Icons.web;
      case DeviceFormFactor.car:
        return Icons.directions_car;
      case DeviceFormFactor.unknown:
        return Icons.devices;
    }
  }

  Widget _buildDeviceName() {
    return Row(
      children: [
        Flexible(
          child: Text(
            device.deviceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (device.isOnline) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceInfo() {
    final platformName = _getPlatformName(device.platform);
    final formFactorName = _getFormFactorName(device.formFactor);

    return Text(
      '$platformName • $formFactorName',
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
      ),
    );
  }

  Widget _buildCurrentPlayback() {
    final content = device.currentContent!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              content.title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformName(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return 'Android';
      case DevicePlatform.ios:
        return 'iOS';
      case DevicePlatform.macos:
        return 'macOS';
      case DevicePlatform.windows:
        return 'Windows';
      case DevicePlatform.linux:
        return 'Linux';
      case DevicePlatform.web:
        return 'Web';
      case DevicePlatform.fireTv:
        return 'Fire TV';
      case DevicePlatform.androidTv:
        return 'Android TV';
      case DevicePlatform.appleTv:
        return 'Apple TV';
      case DevicePlatform.roku:
        return 'Roku';
      case DevicePlatform.androidAuto:
        return 'Android Auto';
      case DevicePlatform.carPlay:
        return 'CarPlay';
      case DevicePlatform.unknown:
        return 'Desconocido';
    }
  }

  String _getFormFactorName(DeviceFormFactor formFactor) {
    switch (formFactor) {
      case DeviceFormFactor.tv:
        return 'TV';
      case DeviceFormFactor.tablet:
        return 'Tablet';
      case DeviceFormFactor.phone:
        return 'Teléfono';
      case DeviceFormFactor.desktop:
        return 'Escritorio';
      case DeviceFormFactor.web:
        return 'Navegador';
      case DeviceFormFactor.car:
        return 'Auto';
      case DeviceFormFactor.unknown:
        return 'Dispositivo';
    }
  }
}
