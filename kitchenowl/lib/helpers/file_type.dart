import 'dart:typed_data';

/// Resolves MIME types and extensions for uploaded document files.
///
/// The backend stores uploads as `uuid.<original extension>` (see
/// `upload_controller.py`), so the extension of a stored filename is
/// authoritative — magic-byte sniffing is a fallback **only** for names
/// with a missing or unknown extension, never an override.
abstract class FileType {
  static const Map<String, String> _mimeByExtension = {
    'pdf': 'application/pdf',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'jxl': 'image/jxl',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'json': 'application/json',
    'zip': 'application/zip',
  };

  /// Magic-byte signatures, checked only when no known extension exists.
  static (String, String)? _sniff(Uint8List bytes) {
    if (bytes.length >= 4 && _startsWith(bytes, [0x25, 0x50, 0x44, 0x46])) {
      return ('pdf', 'application/pdf'); // %PDF
    }
    if (bytes.length >= 3 && _startsWith(bytes, [0xFF, 0xD8, 0xFF])) {
      return ('jpg', 'image/jpeg');
    }
    if (bytes.length >= 4 && _startsWith(bytes, [0x89, 0x50, 0x4E, 0x47])) {
      return ('png', 'image/png'); // .PNG
    }
    if (bytes.length >= 4 && _startsWith(bytes, [0x47, 0x49, 0x46, 0x38])) {
      return ('gif', 'image/gif'); // GIF8
    }

    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    for (int i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }

    return true;
  }

  /// The known extension of [filename], or null when it has none or one
  /// outside the map above.
  static String? _knownExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return null;
    final extension = filename.substring(dot + 1).toLowerCase();

    return _mimeByExtension.containsKey(extension) ? extension : null;
  }

  static bool _hasAnyExtension(String filename) {
    final dot = filename.lastIndexOf('.');

    return dot > 0 && dot != filename.length - 1;
  }

  /// MIME type for [filename], extension-first; [bytes] are sniffed by
  /// magic bytes only when the extension is missing or unknown. Returns
  /// application/octet-stream when nothing matches.
  static String mimeType(String filename, [Uint8List? bytes]) {
    final extension = _knownExtension(filename);
    if (extension != null) return _mimeByExtension[extension]!;
    if (bytes != null) {
      final sniffed = _sniff(bytes);
      if (sniffed != null) return sniffed.$2;
    }

    return 'application/octet-stream';
  }

  /// [filename] guaranteed to end with an extension: when it has none, the
  /// sniffed (or lookup-derived) extension is appended. Names that already
  /// end in any extension are returned untouched.
  static String withExtension(String filename, [Uint8List? bytes]) {
    if (_hasAnyExtension(filename)) return filename;
    String? extension = _knownExtension(filename);
    if (extension == null && bytes != null) {
      extension = _sniff(bytes)?.$1;
    }

    return extension == null ? filename : '$filename.$extension';
  }
}
