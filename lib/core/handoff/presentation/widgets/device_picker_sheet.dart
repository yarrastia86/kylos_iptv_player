// Kylos IPTV Player - Device Picker Sheet
// Bottom sheet for selecting a device to hand off playback to.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/device_presence.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/handoff_providers.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/widgets/available_device_tile.dart';

/// Bottom sheet for selecting a device to send playback to.
class DevicePickerSheet extends ConsumerWidget {
  const DevicePickerSheet({super.key});

  static Future<DevicePresence?> show(BuildContext context) {
    return showModalBottomSheet<DevicePresence>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DevicePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableDevices = ref.watch(availableHandoffDevicesProvider);
    final handoffState = ref.watch(handoffControllerProvider);
    final onlineDevicesAsync = ref.watch(onlineDevicesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.cast, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviar a dispositivo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Continúa viendo en otro dispositivo',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Device list
              Expanded(
                child: onlineDevicesAsync.when(
                  data: (_) => _buildDeviceList(
                    context,
                    ref,
                    availableDevices,
                    handoffState,
                    scrollController,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.amber),
                    ),
                  ),
                  error: (error, _) => _buildErrorState(context, error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    WidgetRef ref,
    List<DevicePresence> devices,
    HandoffState handoffState,
    ScrollController scrollController,
  ) {
    if (devices.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        final isLoading = handoffState.isLoading &&
            handoffState.pendingOutgoingRequest?.toDeviceId == device.deviceId;

        return AvailableDeviceTile(
          device: device,
          isLoading: isLoading,
          onTap: () => _handleDeviceSelected(context, ref, device),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other,
                color: Colors.white38,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin dispositivos disponibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Abre la aplicación en otro dispositivo\npara continuar viendo allí',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to QR pairing screen
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('Vincular TV con código QR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar dispositivos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeviceSelected(
    BuildContext context,
    WidgetRef ref,
    DevicePresence device,
  ) async {
    final controller = ref.read(handoffControllerProvider.notifier);

    // Send the handoff request
    await controller.sendToDevice(device);

    // Check the result
    final state = ref.read(handoffControllerProvider);

    if (state.error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
          ),
        );
        controller.clearError();
      }
    } else if (state.hasPendingOutgoing) {
      // Show pending notification and close sheet
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud enviada a ${device.deviceName}',
            ),
            backgroundColor: Colors.amber.shade800,
            action: SnackBarAction(
              label: 'Cancelar',
              textColor: Colors.white,
              onPressed: () {
                controller.cancelOutgoing();
              },
            ),
          ),
        );
      }
    }
  }
}
