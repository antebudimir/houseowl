import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/model.dart';

/// A household document with optional expiry date, attached file and linked
/// owner. `expiresAt` and `filename` mirror the backend's epoch-ms /
/// embedded-file JSON shape.
class Document extends Model {
  final int? id;
  final String title;
  final String? notes;

  /// UTC instant at which the document expires; null means never expires.
  final DateTime? expiresAt;
  final Member? owner;
  final int? ownerId;

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
    this.owner,
    this.ownerId,
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
      owner: map['owner'] == null
          ? null
          : Member.fromJson(Map<String, dynamic>.from(map['owner'] as Map)),
      ownerId: map['owner_id'],
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
    Member? owner,
    int? ownerId,
    String? filename,
  }) =>
      Document(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        expiresAt: expiresAt ?? this.expiresAt,
        owner: owner ?? this.owner,
        ownerId: ownerId ?? this.ownerId,
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
      [id, title, notes, expiresAt, owner, ownerId, filename, fileBlurHash];

  @override
  String toString() => "Document($id, $title)";

  Map<String, dynamic> toJson() => {
        "title": title,
        "notes": notes,
        "expires_at": expiresAt?.millisecondsSinceEpoch,
        "file_id": filename,
        "owner_id": ownerId ?? owner?.id,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
