import 'package:barcode/barcode.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;

/// Barcode formats accepted by the server (`BARCODE_FORMATS` in
/// `backend/app/models/loyalty_card.py`). The [serverName] strings and this
/// value list must stay in lockstep with the backend whitelist — that
/// contract is asserted in `test/enums/barcode_format_sync_test.dart`.
enum BarcodeFormat {
  code39,
  code93,
  code128,
  ean13,
  ean8,
  isbn,
  itf,
  upca,
  upce,
  codabar,
  qr,
  aztec,
  dataMatrix,
  pdf417,
  rm4scc,
  telepen;

  /// The identifier sent to / received from the server.
  String get serverName {
    switch (this) {
      case BarcodeFormat.dataMatrix:
        return 'dataMatrix';
      default:
        return name;
    }
  }

  static BarcodeFormat? fromServerName(String? name) {
    for (final f in BarcodeFormat.values) {
      if (f.serverName == name) {
        return f;
      }
    }

    return null;
  }

  /// Renderer used on the detail page.
  Barcode toBarcode() {
    switch (this) {
      case BarcodeFormat.code39:
        return Barcode.code39();
      case BarcodeFormat.code93:
        return Barcode.code93();
      case BarcodeFormat.code128:
        return Barcode.code128();
      case BarcodeFormat.ean13:
        return Barcode.ean13();
      case BarcodeFormat.ean8:
        return Barcode.ean8();
      case BarcodeFormat.isbn:
        return Barcode.isbn();
      case BarcodeFormat.itf:
        return Barcode.itf();
      case BarcodeFormat.upca:
        return Barcode.upcA();
      case BarcodeFormat.upce:
        return Barcode.upcE();
      case BarcodeFormat.codabar:
        return Barcode.codabar();
      case BarcodeFormat.qr:
        return Barcode.qrCode();
      case BarcodeFormat.aztec:
        return Barcode.aztec();
      case BarcodeFormat.dataMatrix:
        return Barcode.dataMatrix();
      case BarcodeFormat.pdf417:
        return Barcode.pdf417();
      case BarcodeFormat.rm4scc:
        return Barcode.rm4scc();
      case BarcodeFormat.telepen:
        return Barcode.telepen();
    }
  }

  /// Format hint passed to the mobile scanner. `null` for formats the
  /// scanner stack cannot detect (isbn is reported as ean13; rm4scc and
  /// telepen are not in the zxing set) — those stay manual-entry only.
  scanner.BarcodeFormat? toScannerFormat() {
    switch (this) {
      case BarcodeFormat.isbn:
      case BarcodeFormat.rm4scc:
      case BarcodeFormat.telepen:
        return null;
      case BarcodeFormat.itf:
        return scanner.BarcodeFormat.itf2of5;
      case BarcodeFormat.qr:
        return scanner.BarcodeFormat.qrCode;
      case BarcodeFormat.upca:
        return scanner.BarcodeFormat.upcA;
      case BarcodeFormat.upce:
        return scanner.BarcodeFormat.upcE;
      default:
        return scanner.BarcodeFormat.values.firstWhere(
          (f) => f.name == name,
          orElse: () => scanner.BarcodeFormat.unknown,
        );
    }
  }

  /// The set of formats the camera can auto-detect.
  static List<scanner.BarcodeFormat> get scannableFormats => [
        for (final f in BarcodeFormat.values)
          if (f.toScannerFormat() != null) f.toScannerFormat()!,
      ];

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.barcodeFormatCode39,
      loc.barcodeFormatCode93,
      loc.barcodeFormatCode128,
      loc.barcodeFormatEan13,
      loc.barcodeFormatEan8,
      loc.barcodeFormatIsbn,
      loc.barcodeFormatItf,
      loc.barcodeFormatUpca,
      loc.barcodeFormatUpce,
      loc.barcodeFormatCodabar,
      loc.barcodeFormatQr,
      loc.barcodeFormatAztec,
      loc.barcodeFormatDataMatrix,
      loc.barcodeFormatPdf417,
      loc.barcodeFormatRm4scc,
      loc.barcodeFormatTelepen,
    ][index];
  }
}
