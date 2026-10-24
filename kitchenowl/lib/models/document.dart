import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/person.dart';

/// A household document with optional expiry date, attached file and linked
/// contact. `expiresAt` and `filename` mirror the backend's epoch-ms /
/// embedded-file JSON shape.
class Document extends Model {
  final int? id;
  final String title;
  final String? notes;

  /// UTC instant at which the document expires; null means never expires.
  final DateTime? expiresAt;
  final Person? contact;
  final int? contactId;

  /// Name of the file uploaded through `/api/upload`; doubles as the
  /// backend's `file_id`.
  final String? filename;

  /// BlurHash of the attached image file, as stored by the upload endpoint.
  final String? fileBlurHash;

  const Document({
    this.id,
    this.title = '',
    this.notes,
    this.expiresAt,
    this.contact,
    this.contactId,
    this.filename,
    this.fileBlurHash,
  });

  factory Document.fromJson(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'] ?? '',
      notes: map['notes'],
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['expires_at'],
              isUtc: true,
            ),
      contact: map['contact'] == null
          ? null
          : Person.fromJson(Map<String, dynamic>.from(map['contact'] as Map)),
      contactId: map['contact_id'],
      filename: map['file'] == null
          ? null
          : (map['file'] as Map)['filename'] as String?,
      fileBlurHash: map['file'] == null
          ? null
          : (map['file'] as Map)['blur_hash'] as String?,
    );
  }

  Document copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? expiresAt,
    Person? contact,
    int? contactId,
    String? filename,
  }) =>
      Document(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        expiresAt: expiresAt ?? this.expiresAt,
        contact: contact ?? this.contact,
        contactId: contactId ?? this.contactId,
        filename: filename ?? this.filename,
        fileBlurHash: fileBlurHash ?? this.fileBlurHash,
      );

  bool isExpired([DateTime? now]) {
    now ??= DateTime.now();

    return expiresAt != null && expiresAt!.isBefore(now);
  }

  bool expiresWithin(Duration duration, [DateTime? now]) {
    now ??= DateTime.now();

    return expiresAt != null &&
        !expiresAt!.isBefore(now) &&
        expiresAt!.isBefore(now.add(duration));
  }

  @override
  List<Object?> get props =>
      [id, title, notes, expiresAt, contact, contactId, filename, fileBlurHash];

  @override
  String toString() => "Document($id, $title)";

  Map<String, dynamic> toJson() => {
        "title": title,
        "notes": notes,
        "expires_at": expiresAt?.millisecondsSinceEpoch,
        "file_id": filename,
        "contact_id": contactId ?? contact?.id,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
