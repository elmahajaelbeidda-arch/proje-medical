import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/member_card.dart';

/// Opens the camera and returns the card number and verification code read
/// from a «شفاء للناس» card's QR code, or null if cancelled.
Future<(String, String)?> scanCardQr(BuildContext context) =>
    Navigator.of(context).push<(String, String)>(
      MaterialPageRoute(builder: (_) => const CardScannerScreen()),
    );

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});
  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;
  bool _wrongCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final q = parseCardInput(raw);
      if (q != null) {
        _done = true;
        Navigator.of(context).pop(q);
        return;
      }
    }
    // A QR code that is not one of our cards.
    if (!_wrongCode) setState(() => _wrongCode = true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final box = (size.shortestSide * 0.7).clamp(200.0, 320.0);
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: box,
      height: box,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          context.tr('mc_scan_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('mc_scan_torch'),
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: context.tr('mc_scan_switch'),
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: window,
            onDetect: _onDetect,
            errorBuilder: (ctx, error) => _CameraError(error: error),
          ),
          // Frame and hint, hidden when the camera cannot start.
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, st, _) => st.error != null
                ? const SizedBox.shrink()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Dark veil with a clear square where the code goes.
                      IgnorePointer(
                        child: CustomPaint(painter: _WindowPainter(window)),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        top: window.bottom + 24,
                        child: Column(
                          children: [
                            Text(
                              context.tr(
                                _wrongCode ? 'mc_scan_wrong' : 'mc_scan_hint',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _wrongCode
                                    ? const Color(0xFFBFF2DC)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
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
    );
  }
}

class _WindowPainter extends CustomPainter {
  _WindowPainter(this.window);
  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(window, const Radius.circular(24));
    final veil = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(veil, Paint()..color = Colors.black54);
    canvas.drawRRect(
      r,
      Paint()
        ..color = AppColors.vivid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) => old.window != window;
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(denied ? 'mc_scan_denied' : 'mc_scan_failed'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('mc_scan_back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
