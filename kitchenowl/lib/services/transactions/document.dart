import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

/// Documents are online-only: there is no offline cache, mirroring task
/// transactions.
class TransactionDocumentsGet extends Transaction<List<Document>> {
  final Household household;
  final String? query;
  final int? expiringWithinDays;

  TransactionDocumentsGet({
    required this.household,
    this.query,
    this.expiringWithinDays,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionDocumentsGet",
        );

  @override
  Future<List<Document>> runLocal() async => [];

  @override
  Future<List<Document>> runOnline() async =>
      await ApiService.getInstance().getDocuments(
        household,
        search: query,
        expiringWithinDays: expiringWithinDays,
      ) ??
      [];
}

class TransactionDocumentAdd extends Transaction<bool> {
  final Household household;
  final Document document;

  TransactionDocumentAdd({
    required this.household,
    required this.document,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionDocumentAdd",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addDocument(household, document) != null;
}

class TransactionDocumentUpdate extends Transaction<bool> {
  final Document document;

  TransactionDocumentUpdate({
    required this.document,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionDocumentUpdate",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() =>
      ApiService.getInstance().updateDocument(document);
}

class TransactionDocumentRemove extends Transaction<bool> {
  final Document document;

  TransactionDocumentRemove({
    required this.document,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionDocumentRemove",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() =>
      ApiService.getInstance().deleteDocument(document);
}
