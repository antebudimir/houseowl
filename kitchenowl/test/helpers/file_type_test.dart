import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/helpers/file_type.dart';

Uint8List bytesOf(List<int> signature) => Uint8List.fromList([...signature, 0, 1, 2]);

void main() {
  group('mimeType', () {
    test('known extension wins — sniffing must not override it', () {
      // A .pdf name with PNG magic bytes: the extension is authoritative.
      expect(
        FileType.mimeType('lease.pdf', bytesOf([0x89, 0x50, 0x4E, 0x47])),
        'application/pdf',
      );
      expect(
        FileType.mimeType('photo.png', bytesOf([0x25, 0x50, 0x44, 0x46])),
        'image/png',
      );
    });

    test('case-insensitive extension lookup', () {
      expect(FileType.mimeType('scan.PDF'), 'application/pdf');
      expect(FileType.mimeType('photo.JPG'), 'image/jpeg');
    });

    test('falls back to magic-byte sniffing when extension is unknown', () {
      expect(
        FileType.mimeType('lease.dat', bytesOf([0x25, 0x50, 0x44, 0x46])),
        'application/pdf',
      );
      expect(
        FileType.mimeType('noext', bytesOf([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        FileType.mimeType('noext', bytesOf([0x89, 0x50, 0x4E, 0x47])),
        'image/png',
      );
      expect(
        FileType.mimeType('noext', bytesOf([0x47, 0x49, 0x46, 0x38])),
        'image/gif',
      );
    });

    test('unidentifiable data is application/octet-stream', () {
      expect(FileType.mimeType('noext', bytesOf([1, 2, 3, 4])),
          'application/octet-stream');
      expect(FileType.mimeType('noext'), 'application/octet-stream');
    });
  });

  group('withExtension', () {
    test('never touches a name that already has an extension', () {
      expect(FileType.withExtension('lease.pdf', bytesOf([1, 2, 3, 4])),
          'lease.pdf');
      expect(FileType.withExtension('archive.old', bytesOf([0x25, 0x50, 0x44, 0x46])),
          'archive.old');
    });

    test('appends the sniffed extension to extension-less names', () {
      expect(
        FileType.withExtension('Warranty', bytesOf([0x25, 0x50, 0x44, 0x46])),
        'Warranty.pdf',
      );
      expect(
        FileType.withExtension('photo', bytesOf([0x89, 0x50, 0x4E, 0x47])),
        'photo.png',
      );
    });

    test('returns the name unchanged when nothing can be detected', () {
      expect(FileType.withExtension('mystery', bytesOf([1, 2, 3, 4])), 'mystery');
    });
  });
}
