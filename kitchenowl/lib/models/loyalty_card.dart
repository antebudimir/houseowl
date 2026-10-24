import 'package:kitchenowl/enums/barcode_format_enum.dart';
import 'package:kitchenowl/models/model.dart';

/// A store loyalty card: a card number plus the barcode format used to
/// render it. `barcodeFormat` is the server's format identifier and is
/// resolved through [BarcodeFormat.fromServerName].
class LoyaltyCard extends Model {
  final int? id;
  final String storeName;
  final String cardNumber;
  final String? barcodeFormat;
  final String? notes;

  const LoyaltyCard({
    this.id,
    this.storeName = '',
    this.cardNumber = '',
    this.barcodeFormat,
    this.notes,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> map) {
    return LoyaltyCard(
      id: map['id'],
      storeName: map['store_name'] ?? '',
      cardNumber: map['card_number'] ?? '',
      barcodeFormat: map['barcode_format'],
      notes: map['notes'],
    );
  }

  BarcodeFormat? get format => BarcodeFormat.fromServerName(barcodeFormat);

  /// Masked for list views: `•••• 1234`, or fully masked when too short.
  String get maskedCardNumber {
    if (cardNumber.length <= 4) {
      return '\u2022' * cardNumber.length;
    }

    return '\u2022\u2022\u2022\u2022 ${cardNumber.substring(cardNumber.length - 4)}';
  }

  LoyaltyCard copyWith({
    int? id,
    String? storeName,
    String? cardNumber,
    String? barcodeFormat,
    String? notes,
  }) =>
      LoyaltyCard(
        id: id ?? this.id,
        storeName: storeName ?? this.storeName,
        cardNumber: cardNumber ?? this.cardNumber,
        barcodeFormat: barcodeFormat ?? this.barcodeFormat,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [id, storeName, cardNumber, barcodeFormat, notes];

  @override
  String toString() => "LoyaltyCard($id, $storeName)";

  Map<String, dynamic> toJson() => {
        "store_name": storeName,
        "card_number": cardNumber,
        if (barcodeFormat != null) "barcode_format": barcodeFormat,
        "notes": notes,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
