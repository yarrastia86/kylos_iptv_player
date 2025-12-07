// Kylos IPTV Player - Incoming Handoff Dialog
// Dialog shown when receiving a handoff request from another device.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/handoff/domain/entities/handoff_request.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/handoff_providers.dart';

/// Dialog shown when receiving a handoff request.
class IncomingHandoffDialog extends ConsumerStatefulWidget {
  const IncomingHandoffDialog({
    required this.request,
    super.key,
  });

  final HandoffRequest request;

  /// Shows the incoming handoff dialog.
  static Future<void> show(BuildContext context, HandoffRequest request) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingHandoffDialog(request: request),
    );
  }

  @override
  ConsumerState<IncomingHandoffDialog> createState() =>
      _IncomingHandoffDialogState();
}

class _IncomingHandoffDialogState extends ConsumerState<IncomingHandoffDialog> {
  Timer? _countdownTimer;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final expiresAt = widget.request.expiresAt;
    if (expiresAt != null) {
      _remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          _countdownTimer?.cancel();
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.request.content;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with countdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade800,
                  Colors.amber.shade900,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.cast_connected, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Solicitud de Handoff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_remainingSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // From device info
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.devices,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.fromDeviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'quiere enviar reproducción',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Content preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      if (content.logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            content.logoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderThumb(),
                          ),
                        )
                      else
                        _buildPlaceholderThumb(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatPosition(widget.request.position),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderThumb() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.play_circle_outline,
        color: Colors.white38,
      ),
    );
  }

  String _formatPosition(Duration position) {
    final hours = position.inHours;
    final minutes = position.inMinutes.remainder(60);
    final seconds = position.inSeconds.remainder(60);

    if (hours > 0) {
      return 'Continuar desde ${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return 'Continuar desde ${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAccept() async {
    _countdownTimer?.cancel();

    // Show loading
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.amber),
            ),
            SizedBox(height: 16),
            Text(
              'Iniciando reproducción...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    await ref.read(handoffControllerProvider.notifier).acceptIncoming();

    if (mounted) {
      // Close loading dialog
      Navigator.of(context).pop();
      // Close handoff dialog
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleReject() async {
    _countdownTimer?.cancel();
    await ref.read(handoffControllerProvider.notifier).rejectIncoming();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Listener widget that shows the incoming handoff dialog automatically.
class IncomingHandoffListener extends ConsumerWidget {
  const IncomingHandoffListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<HandoffState>(
      handoffControllerProvider,
      (previous, next) {
        // Show dialog when there's a new incoming request
        if (next.hasIncoming &&
            (previous == null || !previous.hasIncoming)) {
          IncomingHandoffDialog.show(context, next.incomingRequest!);
        }
      },
    );

    return child;
  }
}
