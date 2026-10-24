import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/enums/barcode_format_enum.dart';
import 'package:kitchenowl/models/loyalty_card.dart';

void main() {
  test("fromJson / toJson roundtrip", () {
    final card = LoyaltyCard.fromJson({
      "id": 3,
      "store_name": "SuperMart",
      "card_number": "4006381333931",
      "barcode_format": "ean13",
      "notes": "member card",
    });

    expect(card.id, 3);
    expect(card.storeName, "SuperMart");
    expect(card.cardNumber, "4006381333931");
    expect(card.format, BarcodeFormat.ean13);
    expect(card.notes, "member card");

    final json = card.toJsonWithId();
    expect(json["id"], 3);
    expect(json["store_name"], "SuperMart");
    expect(json["card_number"], "4006381333931");
    expect(json["barcode_format"], "ean13");
    expect(json["notes"], "member card");
  });

  test("toJson omits barcode_format when unset", () {
    final json = const LoyaltyCard(
      storeName: "Kiosk",
      cardNumber: "42",
    ).toJson();

    expect(json.containsKey("barcode_format"), isFalse);
    expect(json["notes"], isNull);
  });

  test("maskedCardNumber shows only the last four digits", () {
    expect(
      const LoyaltyCard(cardNumber: "4006381333931").maskedCardNumber,
      "\u2022\u2022\u2022\u2022 3931",
    );
    // Short numbers are masked entirely — nothing to reveal.
    expect(
      const LoyaltyCard(cardNumber: "1234").maskedCardNumber,
      "\u2022\u2022\u2022\u2022",
    );
  });

  test("fromServerName resolves dataMatrix case-sensitively", () {
    expect(
        BarcodeFormat.fromServerName("dataMatrix"), BarcodeFormat.dataMatrix);
    expect(BarcodeFormat.fromServerName("datamatrix"), isNull);
    expect(BarcodeFormat.fromServerName(null), isNull);
  });

  test("copyWith replaces fields", () {
    const card = LoyaltyCard(
      id: 1,
      storeName: "A",
      cardNumber: "1",
      barcodeFormat: "qr",
    );
    final updated = card.copyWith(cardNumber: "2", notes: "n");

    expect(updated.storeName, "A");
    expect(updated.cardNumber, "2");
    expect(updated.barcodeFormat, "qr");
    expect(updated.notes, "n");
  });
}
