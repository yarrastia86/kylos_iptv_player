// Kylos IPTV Player - Mobile Pairing Scanner Screen
// Screen for scanning TV pairing QR codes from mobile.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kylos_iptv_player/core/handoff/presentation/tv_pairing_providers.dart';

/// Screen for scanning TV pairing QR codes.
class MobilePairingScannerScreen extends ConsumerStatefulWidget {
  const MobilePairingScannerScreen({super.key});

  @override
  ConsumerState<MobilePairingScannerScreen> createState() =>
      _MobilePairingScannerScreenState();
}

class _MobilePairingScannerScreenState
    extends ConsumerState<MobilePairingScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _showManualEntry = false;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.resumed) {
      _controller?.start();
    } else if (state == AppLifecycleState.paused) {
      _controller?.stop();
    }
  }

  void _initScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.startsWith('kylos://pair?session=')) {
        setState(() => _hasScanned = true);
        _controller?.stop();
        ref.read(mobilePairingScannerProvider.notifier).handleScannedUrl(code);
        HapticFeedback.mediumImpact();
        break;
      }
    }
  }

  void _handleManualCode() {
    final code = _codeController.text.trim();
    if (code.length == 6) {
      ref.read(mobilePairingScannerProvider.notifier).handleNumericCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mobilePairingScannerProvider);

    // Listen for errors
    ref.listen<MobilePairingScannerState>(
      mobilePairingScannerProvider,
      (previous, next) {
        if (next.error != null && previous?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(mobilePairingScannerProvider.notifier).clearError();
          // Reset scan state to allow retry
          setState(() => _hasScanned = false);
          _controller?.start();
        }
      },
    );

    // Show success screen when completed
    if (state.isCompleted) {
      return _buildSuccessScreen(state.pairedDeviceName);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Vincular TV'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _showManualEntry = !_showManualEntry);
            },
            child: Text(
              _showManualEntry ? 'Escanear QR' : 'Código manual',
              style: const TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_showManualEntry)
            _buildManualEntry(state)
          else
            _buildScanner(),

          // Loading overlay
          if (state.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.amber),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Vinculando...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera preview
        if (_controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: _handleBarcode,
          ),

        // Scanning overlay
        CustomPaint(
          painter: _ScannerOverlayPainter(),
          child: const SizedBox.expand(),
        ),

        // Instructions
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código QR en la TV',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Torch toggle
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: IconButton(
              onPressed: () => _controller?.toggleTorch(),
              icon: ValueListenableBuilder(
                valueListenable: _controller!.torchState,
                builder: (context, state, _) {
                  return Icon(
                    state == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                    size: 32,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry(MobilePairingScannerState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pin,
            color: Colors.amber,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ingresa el código de 6 dígitos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El código aparece en la pantalla de tu TV',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 32,
                  letterSpacing: 8,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.length == 6) {
                  _handleManualCode();
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: state.isLoading ? null : _handleManualCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(String? deviceName) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡TV vinculado!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                deviceName != null
                    ? 'Tu cuenta ha sido vinculada a "$deviceName"'
                    : 'Tu cuenta ha sido vinculada a la TV',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for scanner overlay.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Scanner box dimensions
    const boxSize = 250.0;
    final boxRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: boxSize,
      height: boxSize,
    );

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(16)));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.top + cornerLength)
        ..lineTo(boxRect.left, boxRect.top + radius)
        ..quadraticBezierTo(
          boxRect.left,
          boxRect.top,
          boxRect.left + radius,
          boxRect.top,
        )
        ..lineTo(boxRect.left + cornerLength, boxRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - cornerLength, boxRect.top)
        ..lineTo(boxRect.right - radius, boxRect.top)
        ..quadraticBezierTo(
          boxRect.right,
          boxRect.top,
          boxRect.right,
          boxRect.top + radius,
        )
        ..lineTo(boxRect.right, boxRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.bottom - cornerLength)
        ..lineTo(boxRect.left, boxRect.bottom - radius)
        ..quadraticBezierTo(
          boxRect.left,
          boxRect.bottom,
          boxRect.left + radius,
          boxRect.bottom,
        )
        ..lineTo(boxRect.left + cornerLength, boxRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - cornerLength, boxRect.bottom)
        ..lineTo(boxRect.right - radius, boxRect.bottom)
        ..quadraticBezierTo(
          boxRect.right,
          boxRect.bottom,
          boxRect.right,
          boxRect.bottom - radius,
        )
        ..lineTo(boxRect.right, boxRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
