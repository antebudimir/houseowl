import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:houseowl/helpers/named_bytearray.dart';
import 'package:houseowl/services/api/api_service.dart';

extension UploadApi on ApiService {
  static const baseRoute = '/upload';

  Future<String?> uploadBytes(NamedByteArray file) async {
    final res = await postBytes(baseRoute, file);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);

    return body['filename'];
  }

  /// Downloads an uploaded file (e.g. a document attachment) by its stored
  /// filename. Authorization is handled server-side via the file's household.
  Future<Uint8List?> downloadBytes(String filename) async {
    final res = await get('$baseRoute/$filename', refreshOnException: false);
    if (res.statusCode != 200) return null;

    return res.bodyBytes;
  }
}
