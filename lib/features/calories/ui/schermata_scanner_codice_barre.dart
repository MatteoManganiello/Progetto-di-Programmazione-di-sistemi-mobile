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
  final _re = RegExp(r'^\d{8,14}$'); // EAN/UPC classici
  final _controller = MobileScannerController(
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );

  bool _returned = false;
  bool _torchOn = false; // stato locale per l’icona torcia

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_returned) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue ?? '';
      if (value.isEmpty) continue;
      if (!_re.hasMatch(value)) continue; // filtra solo EAN/UPC

      _returned = true;
      if (!mounted) return;
      Navigator.pop(context, value); // torna con il barcode
      break;
    }
  }

  void _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _torchOn = !_torchOn); // aggiorna solo l'icona locale
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile attivare la torcia: $e')),
      );
    }
  }

  Future<void> _manualInput() async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Inserisci codice'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'EAN/UPC 8–14 cifre',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );

    if (code == null) return;
    if (_re.hasMatch(code)) {
      if (!mounted) return;
      _returned = true;
      Navigator.pop(context, code);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EAN/UPC non valido (8–14 cifre)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Codice a Barre'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Torcia',
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Cambia camera',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Anteprima camera + decoding
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Errore fotocamera: $error\nControlla i permessi.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          // Overlay con mirino
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),

          // Pulsante per input manuale
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _manualInput,
                    icon: const Icon(Icons.edit),
                    label: const Text('Inserisci manualmente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      backgroundColor: Colors.black45,
                    ),
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
