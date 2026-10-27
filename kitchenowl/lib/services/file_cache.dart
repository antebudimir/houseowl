import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

/// Persistent on-device cache for document files, partitioned per household.
///
/// Files are stored under `<app support>/files/<householdId>/<filename>` so
/// that pruning one household's vault can never touch another's. The app
/// support directory is used (instead of the temporary cache directory)
/// because documents must survive cache eviction to stay available offline.
class FileCache {
  static FileCache? _instance;

  FileCache._internal();
  static FileCache getInstance() {
    _instance ??= FileCache._internal();

    return _instance!;
  }

  Directory? _baseDir;

  Future<String> _householdDir(int householdId) async {
    _baseDir ??= Directory(
      '${(await pathProvider.getApplicationSupportDirectory()).path}'
      '${Platform.pathSeparator}files',
    );
    final dir = Directory(
      '${_baseDir!.path}${Platform.pathSeparator}$householdId',
    );
    if (!await dir.exists()) await dir.create(recursive: true);

    return dir.path;
  }

  /// Server filenames are generated (uuid + extension), but sanitize anyway
  /// so a hostile value can never escape the household directory.
  static String _safeName(String filename) =>
      filename.replaceAll(RegExp(r'[/\\]'), '_');

  Future<File> _file(int householdId, String filename) async {
    final dir = await _householdDir(householdId);

    return File('$dir${Platform.pathSeparator}${_safeName(filename)}');
  }

  Future<bool> exists(int householdId, String filename) async {
    if (kIsWeb) return false;

    try {
      return await (await _file(householdId, filename)).exists();
    } on FileSystemException {
      return false;
    }
  }

  /// Returns the cached bytes or null when the file is not cached (or the
  /// cache is unreadable, in which case callers fall back to downloading).
  Future<Uint8List?> readBytes(int householdId, String filename) async {
    if (kIsWeb) return null;

    try {
      final file = await _file(householdId, filename);
      if (!await file.exists()) return null;

      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Best-effort write: a failed cache write only degrades offline
  /// availability, so the error is swallowed after logging.
  Future<void> writeBytes(int householdId, String filename, Uint8List bytes) async {
    if (kIsWeb) return;

    try {
      final file = await _file(householdId, filename);
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      debugPrint('FileCache: failed to cache $filename: $e');
    }
  }

  Future<void> delete(int householdId, String filename) async {
    if (kIsWeb) return;

    try {
      final file = await _file(householdId, filename);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (e) {
      debugPrint('FileCache: failed to delete $filename: $e');
    }
  }

  /// All filenames currently cached for the household (sanitized names, which
  /// round-trip through [_safeName] unchanged for server-generated names).
  Future<Set<String>> listFilenames(int householdId) async {
    if (kIsWeb) return {};

    try {
      final dir = Directory(await _householdDir(householdId));

      return (await dir.list().toList())
          .whereType<File>()
          .map((e) => e.uri.pathSegments.last)
          .toSet();
    } on FileSystemException {
      return {};
    }
  }
}
