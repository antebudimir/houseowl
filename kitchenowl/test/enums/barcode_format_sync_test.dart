import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/enums/barcode_format_enum.dart';

/// The client enum must mirror the server's barcode-format whitelist
/// exactly: the backend `BARCODE_FORMATS` frozenset lives in
/// backend/app/models/loyalty_card.py.
void main() {
  test("client BarcodeFormat values match the backend whitelist", () {
    final backendFile = File(
      "../backend/app/models/loyalty_card.py",
    );
    expect(
      backendFile.existsSync(),
      isTrue,
      reason: "run the flutter tests from the kitchenowl/ directory",
    );

    // Extract e.g. BARCODE_FORMATS = frozenset({"ean13", ...}).
    final source = backendFile.readAsStringSync();
    final match = RegExp(
      r'BARCODE_FORMATS\s*=\s*frozenset\(\s*\{(.*?)\}',
      dotAll: true,
    ).firstMatch(source);
    expect(match, isNotNull);

    final serverFormats = RegExp(r'"([a-zA-Z0-9]+)"')
        .allMatches(match!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();

    final clientFormats = BarcodeFormat.values.map((f) => f.serverName).toSet();

    expect(clientFormats, serverFormats);
  });

  test("scannable formats exclude manual-only formats", () {
    final scannableServerNames = <String>{
      for (final f in BarcodeFormat.values)
        if (f.toScannerFormat() != null) f.serverName,
    };

    expect(scannableServerNames.contains("isbn"), isFalse);
    expect(scannableServerNames.contains("rm4scc"), isFalse);
    expect(scannableServerNames.contains("telepen"), isFalse);
    expect(scannableServerNames.contains("ean13"), isTrue);
    expect(scannableServerNames.contains("qr"), isTrue);
  });
}
