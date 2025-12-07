// Kylos IPTV Player - Handoff Button
// Button for initiating playback handoff from the player controls.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/handoff_providers.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/widgets/device_picker_sheet.dart';

/// Button that shows available devices for handoff.
class HandoffButton extends ConsumerWidget {
  const HandoffButton({
    super.key,
    this.iconSize = 24.0,
    this.color,
  });

  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDevices = ref.watch(hasAvailableDevicesProvider);
    final handoffState = ref.watch(handoffControllerProvider);

    // Don't show if no devices available and no pending request
    if (!hasDevices && !handoffState.hasPendingOutgoing) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: handoffState.isLoading
          ? null
          : () => _onPressed(context, handoffState),
      icon: _buildIcon(handoffState),
      tooltip: _getTooltip(handoffState),
    );
  }

  Widget _buildIcon(HandoffState state) {
    if (state.isLoading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.amber),
        ),
      );
    }

    if (state.hasPendingOutgoing) {
      return Icon(
        Icons.cast_connected,
        size: iconSize,
        color: Colors.amber,
      );
    }

    return Icon(
      Icons.cast,
      size: iconSize,
      color: color ?? Colors.white,
    );
  }

  String _getTooltip(HandoffState state) {
    if (state.hasPendingOutgoing) {
      return 'Esperando respuesta...';
    }
    return 'Enviar a dispositivo';
  }

  void _onPressed(BuildContext context, HandoffState state) {
    if (state.hasPendingOutgoing) {
      // Show cancel option
      _showPendingDialog(context);
    } else {
      DevicePickerSheet.show(context);
    }
  }

  void _showPendingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _PendingHandoffDialog(),
    );
  }
}

/// Dialog shown when there's a pending outgoing handoff request.
class _PendingHandoffDialog extends ConsumerWidget {
  const _PendingHandoffDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handoffState = ref.watch(handoffControllerProvider);
    final request = handoffState.pendingOutgoingRequest;

    if (request == null) {
      // Request was completed, close dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        'Esperando respuesta',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            'Esperando que ${request.toDeviceName} acepte la solicitud...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (request.expiresAt != null)
            Text(
              'La solicitud expira en ${_getRemainingTime(request.expiresAt!)} segundos',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(handoffControllerProvider.notifier).cancelOutgoing();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  int _getRemainingTime(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

/// Larger handoff button for TV interfaces.
class HandoffButtonTV extends ConsumerWidget {
  const HandoffButtonTV({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDevices = ref.watch(hasAvailableDevicesProvider);
    final handoffState = ref.watch(handoffControllerProvider);

    if (!hasDevices && !handoffState.hasPendingOutgoing) {
      return const SizedBox.shrink();
    }

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: hasFocus
                  ? Colors.amber
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? Colors.amber : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  handoffState.hasPendingOutgoing
                      ? Icons.cast_connected
                      : Icons.cast,
                  color: hasFocus ? Colors.black : Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  handoffState.hasPendingOutgoing
                      ? 'Esperando...'
                      : 'Enviar a otro dispositivo',
                  style: TextStyle(
                    color: hasFocus ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
