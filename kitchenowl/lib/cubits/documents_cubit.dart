import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/enums/documents_filter_enum.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/document.dart';

class DocumentsCubit extends Cubit<DocumentsCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  List<Document> documentList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;
  DocumentsFilter _refreshCurrentFilter = DocumentsFilter.all;

  DocumentsCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingDocumentsCubitState()) {
    refresh();
    ApiService.getInstance().onDocumentUpdate(onDocumentUpdate);
  }

  DocumentsCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingDocumentsCubitState()) {
    refresh();
  }

  DocumentsFilter get filter => (state is ListDocumentsCubitState)
      ? (state as ListDocumentsCubitState).filter
      : DocumentsFilter.all;

  String get query => (state is SearchDocumentsCubitState)
      ? (state as SearchDocumentsCubitState).query
      : "";

  void onDocumentUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addDocument(Document document) async {
    final res = await _transactionHandler.runTransaction(TransactionDocumentAdd(
      household: household,
      document: document,
    ));
    await refresh();

    return res;
  }

  Future<bool> updateDocument(Document document) async {
    final res =
        await _transactionHandler.runTransaction(TransactionDocumentUpdate(
      document: document,
    ));
    await refresh();

    return res;
  }

  Future<bool> deleteDocument(Document document) async {
    final res =
        await _transactionHandler.runTransaction(TransactionDocumentRemove(
      document: document,
    ));
    await refresh();

    return res;
  }

  /// Delegates the search to the server (ILIKE over title and notes) through
  /// the transaction handler. The debouncing lives in the search anchor.
  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> setFilter(DocumentsFilter f) {
    return refresh(null, f);
  }

  Future<void> refresh([String? query, DocumentsFilter? f]) {
    final state = this.state;
    if (f == null && state is ListDocumentsCubitState) {
      f = state.filter;
    }
    if (state is SearchDocumentsCubitState) {
      query = query ?? state.query;
    }
    if (_refreshThread == null ||
        query != _refreshCurrentQuery ||
        f != _refreshCurrentFilter) {
      _refreshCurrentQuery = query;
      _refreshCurrentFilter = f ?? DocumentsFilter.all;
      _refreshThread = _refresh(query, f);
    }

    return _refreshThread!;
  }

  Future<void> _refresh([String? query, DocumentsFilter? f]) async {
    final filter = f ?? DocumentsFilter.all;
    if (state is ListDocumentsCubitState &&
        state is! SearchDocumentsCubitState &&
        (state as ListDocumentsCubitState).documents.isEmpty) {
      emit(const LoadingDocumentsCubitState());
    }
    documentList = await _transactionHandler.runTransaction(
      TransactionDocumentsGet(
        household: household,
        query: query,
        expiringWithinDays: filter.days,
      ),
    );

    final DocumentsCubitState newState = (query != null && query.isNotEmpty)
        ? SearchDocumentsCubitState(
            query: query,
            documents: documentList,
            filter: filter,
          )
        : ListDocumentsCubitState(documents: documentList, filter: filter);
    if (_refreshCurrentQuery == query && _refreshCurrentFilter == filter) {
      emit(newState);
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offDocumentUpdate(onDocumentUpdate);
    super.close();
  }
}

abstract class DocumentsCubitState extends Equatable {
  const DocumentsCubitState();

  List<Document> get documents => const [];

  @override
  List<Object?> get props => const [];
}

class LoadingDocumentsCubitState extends DocumentsCubitState {
  const LoadingDocumentsCubitState();
}

class ListDocumentsCubitState extends DocumentsCubitState {
  final List<Document> documents;
  final DocumentsFilter filter;

  const ListDocumentsCubitState({
    this.documents = const [],
    this.filter = DocumentsFilter.all,
  });

  /// Documents expiring within 30 days (already-expired included, matching
  /// the backend's `expiring_within` semantics), soonest first.
  List<Document> get expiringSoon {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 30));

    return documents
        .where((d) => d.expiresAt != null && d.expiresAt!.isBefore(horizon))
        .toList()
      ..sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));
  }

  @override
  List<Object?> get props => <Object?>[...documents, filter];
}

class SearchDocumentsCubitState extends ListDocumentsCubitState {
  final String query;

  const SearchDocumentsCubitState({
    required this.query,
    super.documents,
    super.filter,
  });

  @override
  List<Object?> get props => super.props + [query];
}
