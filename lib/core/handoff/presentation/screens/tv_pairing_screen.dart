// Kylos IPTV Player - TV Pairing Screen
// Screen displayed on TV for QR code authentication.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/tv_pairing_providers.dart';

/// Screen displayed on TV for pairing via QR code.
class TvPairingScreen extends ConsumerStatefulWidget {
  const TvPairingScreen({super.key});

  @override
  ConsumerState<TvPairingScreen> createState() => _TvPairingScreenState();
}

class _TvPairingScreenState extends ConsumerState<TvPairingScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Start pairing session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tvPairingControllerProvider.notifier).startPairing();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _updateRemainingTime(expiresAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime(expiresAt);
    });
  }

  void _updateRemainingTime(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    if (mounted) {
      setState(() {
        _remainingSeconds = remaining > 0 ? remaining : 0;
      });
      if (remaining <= 0) {
        _countdownTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tvPairingControllerProvider);

    // Listen for session changes to update countdown
    ref.listen<TvPairingState>(
      tvPairingControllerProvider,
      (previous, next) {
        if (next.session != null && next.session != previous?.session) {
          _startCountdown(next.session!.expiresAt);
        }
      },
    );

    // Show success screen when paired
    if (state.isPaired) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: state.isLoading
                ? _buildLoadingState()
                : state.error != null
                    ? _buildErrorState(state.error!)
                    : state.hasActiveSession
                        ? _buildPairingContent(state)
                        : _buildExpiredState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.amber),
        ),
        SizedBox(height: 24),
        Text(
          'Generando código de emparejamiento...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          error,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(tvPairingControllerProvider.notifier).startPairing();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Intentar de nuevo',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.timer_off,
          color: Colors.white54,
          size: 64,
        ),
        const SizedBox(height: 24),
        const Text(
          'Sesión de emparejamiento expirada',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(tvPairingControllerProvider.notifier).startPairing();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Generar nuevo código',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPairingContent(TvPairingState state) {
    final session = state.session!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR Code section
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: session.qrCodeData,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expira en ${_formatTime(_remainingSeconds)}',
              style: TextStyle(
                color: _remainingSeconds < 60 ? Colors.red : Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(width: 64),

        // Instructions section
        SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vincular TV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Step 1
              _buildStep(
                number: '1',
                text: 'Abre Kylos en tu teléfono',
              ),
              const SizedBox(height: 16),

              // Step 2
              _buildStep(
                number: '2',
                text: 'Ve a Configuración > Vincular TV',
              ),
              const SizedBox(height: 16),

              // Step 3
              _buildStep(
                number: '3',
                text: 'Escanea el código QR',
              ),

              const SizedBox(height: 32),

              // Divider with "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O ingresa el código',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white24)),
                ],
              ),

              const SizedBox(height: 24),

              // Numeric code
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _formatCode(session.code),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Refresh button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(tvPairingControllerProvider.notifier).refreshSession();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  label: const Text(
                    'Generar nuevo código',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Vinculación exitosa!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu cuenta ha sido vinculada a este dispositivo.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatCode(String code) {
    // Format as "123 456" for readability
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }
}
