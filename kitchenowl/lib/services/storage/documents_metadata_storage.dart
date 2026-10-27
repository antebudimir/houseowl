import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:houseowl/models/document.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

/// Offline cache of a household's document *metadata* (the vault list), so
/// the documents page can render without connectivity. File bytes live in
/// [FileCache]; this only stores the list itself.
class DocumentsMetadataStorage {
  static DocumentsMetadataStorage? _instance;

  DocumentsMetadataStorage._internal();
  static DocumentsMetadataStorage getInstance() {
    _instance ??= DocumentsMetadataStorage._internal();

    return _instance!;
  }

  Future<File> _file(int householdId) async {
    final path = (await pathProvider.getApplicationSupportDirectory()).path;

    return File('$path${Platform.pathSeparator}documents_$householdId.json');
  }

  /// Stores the current list. Only the fields the vault UI needs offline are
  /// kept; the JSON reuses [Document.fromJson]'s embedded-`file` shape.
  Future<void> save(int householdId, List<Document> documents) async {
    if (kIsWeb) return;

    try {
      await (await _file(householdId)).writeAsString(
        json.encode(
          documents
              .map(
                (d) => {
                  "id": d.id,
                  "title": d.title,
                  "notes": d.notes,
                  "expires_at": d.expiresAt?.millisecondsSinceEpoch,
                  if (d.owner != null) "owner": d.owner!.toJsonWithId(),
                  "owner_id": d.ownerId,
                  if (d.filename != null)
                    "file": {
                      "filename": d.filename,
                      if (d.fileBlurHash != null) "blur_hash": d.fileBlurHash,
                    },
                },
              )
              .toList(),
        ),
        flush: true,
      );
    } on FileSystemException catch (e) {
      debugPrint('DocumentsMetadataStorage: failed to save: $e');
    }
  }

  /// The last successfully fetched list, or null when nothing was cached yet.
  Future<List<Document>?> load(int householdId) async {
    if (kIsWeb) return null;

    try {
      final file = await _file(householdId);
      if (!await file.exists()) return null;

      return List<Document>.from(
        json
            .decode(await file.readAsString())
            .map((e) => Document.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      debugPrint('DocumentsMetadataStorage: failed to load: $e');

      return null;
    }
  }
}
