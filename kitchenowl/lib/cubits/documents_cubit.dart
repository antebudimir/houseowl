import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/enums/documents_filter_enum.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/file_cache.dart';
import 'package:houseowl/services/storage/documents_metadata_storage.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/document.dart';

class DocumentsCubit extends Cubit<DocumentsCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;

  /// Whether document files and metadata are persisted locally for offline
  /// access. Disabled for testing, where platform channels are unavailable.
  final bool _persistenceEnabled;
  List<Document> documentList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;
  DocumentsFilter _refreshCurrentFilter = DocumentsFilter.all;
  final Set<String> _syncingFiles = {};

  DocumentsCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        _persistenceEnabled = true,
        super(const LoadingDocumentsCubitState()) {
    refresh();
    ApiService.getInstance().onDocumentUpdate(onDocumentUpdate);
  }

  DocumentsCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        _persistenceEnabled = false,
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

    // A complete list is one fetched online with no search text and no
    // expiry filter — the only kind that is safe to persist as "the vault"
    // and to prune the file cache against. Search results and filtered
    // subsets are partial, so they must never prune.
    final isComplete =
        (query == null || query.isEmpty) && filter == DocumentsFilter.all;
    if (_persistenceEnabled) {
      if (ApiService.getInstance().isConnected()) {
        if (isComplete) {
          await DocumentsMetadataStorage.getInstance()
              .save(household.id, documentList);
        }
        unawaited(_syncDocumentFiles(allowPrune: isComplete));
      } else if (documentList.isEmpty) {
        // Offline: fall back to the last known vault so it stays browsable.
        final cached =
            await DocumentsMetadataStorage.getInstance().load(household.id);
        if (cached != null) documentList = cached;
      }
    }

    final DocumentsCubitState newState = (query != null && query.isNotEmpty)
        ? SearchDocumentsCubitState(
            query: query,
            documents: documentList,
            filter: filter,
            downloadingFiles: Set.of(_syncingFiles),
          )
        : ListDocumentsCubitState(
            documents: documentList,
            filter: filter,
            downloadingFiles: Set.of(_syncingFiles),
          );
    if (_refreshCurrentQuery == query && _refreshCurrentFilter == filter) {
      emit(newState);
      _refreshThread = null;
    }
  }

  /// Whether the attachment of [filename] is currently being downloaded.
  bool isSyncingFile(String? filename) =>
      filename != null && _syncingFiles.contains(filename);

  /// Re-emits the current list state so tiles can react to sync progress.
  void _emitFileStatus() {
    final s = state;
    if (s is ListDocumentsCubitState) {
      emit(s.copyWithDownloadingFiles(Set.of(_syncingFiles)));
    }
  }

  /// Downloads every document file that is not cached yet and, after a
  /// complete list fetch, prunes cached files that no longer exist
  /// server-side. Failures are non-fatal: the file simply stays unavailable
  /// offline and the attempt is retried on the next refresh.
  Future<void> _syncDocumentFiles({required bool allowPrune}) async {
    final householdId = household.id;
    final cache = FileCache.getInstance();
    final remoteFilenames = documentList
        .map((d) => d.filename)
        .whereType<String>()
        .toSet();

    if (allowPrune) {
      for (final cached in await cache.listFilenames(householdId)) {
        if (!remoteFilenames.contains(cached)) {
          await cache.delete(householdId, cached);
        }
      }
    }

    for (final document in documentList) {
      final filename = document.filename;
      if (filename == null ||
          _syncingFiles.contains(filename) ||
          await cache.exists(householdId, filename)) {
        continue;
      }
      _syncingFiles.add(filename);
      _emitFileStatus();
      try {
        final bytes = await ApiService.getInstance().downloadBytes(filename);
        if (bytes != null) {
          await cache.writeBytes(householdId, filename, bytes);
        }
      } catch (e) {
        debugPrint('FileCache: sync of $filename failed: $e');
      } finally {
        _syncingFiles.remove(filename);
        _emitFileStatus();
      }
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

  /// Filenames whose file is currently being downloaded in the background.
  final Set<String> downloadingFiles;

  const ListDocumentsCubitState({
    this.documents = const [],
    this.filter = DocumentsFilter.all,
    this.downloadingFiles = const {},
  });

  ListDocumentsCubitState copyWithDownloadingFiles(
    Set<String> downloadingFiles,
  ) =>
      ListDocumentsCubitState(
        documents: documents,
        filter: filter,
        downloadingFiles: downloadingFiles,
      );

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
  List<Object?> get props =>
      <Object?>[...documents, filter, downloadingFiles];
}

class SearchDocumentsCubitState extends ListDocumentsCubitState {
  final String query;

  const SearchDocumentsCubitState({
    required this.query,
    super.documents,
    super.filter,
    super.downloadingFiles,
  });

  @override
  List<Object?> get props => super.props + [query];
}
