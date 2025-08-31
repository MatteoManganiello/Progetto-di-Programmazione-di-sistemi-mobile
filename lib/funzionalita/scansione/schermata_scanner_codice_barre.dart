import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SchermataScannerCodiceBarre extends StatefulWidget {
  const SchermataScannerCodiceBarre({super.key});

  @override
  State<SchermataScannerCodiceBarre> createState() =>
      _SchermataScannerCodiceBarreState();
}

class _SchermataScannerCodiceBarreState
    extends State<SchermataScannerCodiceBarre> {
  final MobileScannerController _controller = MobileScannerController(
    // Configurazioni utili; modifica se vuoi
    detectionSpeed: DetectionSpeed.normal,
    torchEnabled: false,
    facing: CameraFacing.back,
    returnImage: false,
  );

  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    _handling = true;
    await _controller.stop();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Codice rilevato'),
        content: SelectableText(value),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiato negli appunti')),
                );
              }
            },
            child: const Text('Copia'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // chiude il dialog
              Navigator.of(context).maybePop(value); // ritorna il valore allo schermo precedente (se usi push)
            },
            child: const Text('Usa valore'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );

    // Riavvia lo scanner e sblocca
    if (mounted) {
      await _controller.start();
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner codici a barre'),
        actions: [
          // Stato/Toggle del flash con la nuova API (controller.value.torchState)
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final torch = state.torchState;
              final canUseTorch = torch != TorchState.unavailable;

              return IconButton(
                tooltip: canUseTorch
                    ? (torch == TorchState.on ? 'Spegni flash' : 'Accendi flash')
                    : 'Flash non disponibile',
                onPressed: canUseTorch ? () => _controller.toggleTorch() : null,
                icon: Icon(
                  torch == TorchState.on ? Icons.flash_on : Icons.flash_off,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cambia fotocamera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              final code = error.errorCode;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        switch (code) {
                          MobileScannerErrorCode.permissionDenied =>
                            'Permesso fotocamera negato. Concedi il permesso nelle impostazioni.',
                          MobileScannerErrorCode.unsupported =>
                            'Scanner non supportato su questo dispositivo.',
                          _ => 'Errore scanner: $code',
                        },
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const _ScannerOverlay(cutOutSize: 260),
          const Align(
            alignment: Alignment(0, 0.85),
            child: Text(
              'Allinea il codice nell’area',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay scuro con “finestra” centrale e bordo
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.cutOutSize});

  final double cutOutSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(cutOutSize: cutOutSize),
      size: Size.infinite,
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.cutOutSize});

  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final full = Path()..addRect(Offset.zero & size);

    final center = Offset(size.width / 2, size.height * 0.38);
    final rect = Rect.fromCenter(center: center, width: cutOutSize, height: cutOutSize);
    final hole = Path()..addRRect(RRect.fromRectXY(rect, 16, 16));

    final diff = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(diff, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectXY(rect, 16, 16), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.cutOutSize != cutOutSize;
}
