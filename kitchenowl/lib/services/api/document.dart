import 'dart:convert';

import 'package:kitchenowl/models/document.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension DocumentApi on ApiService {
  String documentRoute({Household? household, Document? document}) =>
      "${household != null ? householdPath(household) : ""}/document${document?.id != null ? "/${document!.id}" : ""}";

  Future<List<Document>?> getDocuments(
    Household household, {
    String? search,
    int? expiringWithinDays,
  }) async {
    final res = await get(
      documentRoute(household: household),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (expiringWithinDays != null)
          'expiring_within': '${expiringWithinDays}d',
      },
    );
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Document.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Document?> addDocument(Household household, Document document) async {
    final res = await post(
      documentRoute(household: household),
      jsonEncode(document.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Document.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateDocument(Document document) async {
    final res = await post(
      documentRoute(document: document),
      jsonEncode(document.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteDocument(Document document) async {
    final res = await delete(documentRoute(document: document));

    return res.statusCode == 200;
  }

  void onDocumentUpdate(dynamic Function(dynamic) handler) {
    socket.on("document:update", handler);
  }

  void offDocumentUpdate(dynamic Function(dynamic) handler) {
    socket.off("document:update", handler);
  }
}
