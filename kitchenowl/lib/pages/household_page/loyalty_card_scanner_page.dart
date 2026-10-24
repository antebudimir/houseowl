import 'package:material_ui/material_ui.dart';
import 'package:houseowl/enums/barcode_format_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;

/// Full-screen camera scanner. Formats are auto-detected: the first
/// successfully scanned barcode wins, and its detected format is reported
/// back (mapped to a server format when possible) alongside the raw value.
class LoyaltyCardScannerPage extends StatefulWidget {
  const LoyaltyCardScannerPage({super.key});

  @override
  State<LoyaltyCardScannerPage> createState() => _LoyaltyCardScannerPageState();
}

class _LoyaltyCardScannerPageState extends State<LoyaltyCardScannerPage> {
  final scanner.MobileScannerController _controller =
      scanner.MobileScannerController(
    formats: BarcodeFormat.scannableFormats,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(scanner.BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue == null || barcode.rawValue!.isEmpty) continue;
      _handled = true;
      // Match the detected scanner format back to a server format.
      String? serverName;
      for (final f in BarcodeFormat.values) {
        if (f.toScannerFormat() == barcode.format) {
          serverName = f.serverName;
          break;
        }
      }
      Navigator.of(context).pop({
        'number': barcode.rawValue!,
        // Unknown scanner formats fall back to '' and keep the previous
        // manual selection on the add/update page.
        'format': serverName ?? '',
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.loyaltyCardScan),
      ),
      body: Stack(
        children: [
          scanner.MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.loyaltyCardScanHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(loc.loyaltyCardEnterManually),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
