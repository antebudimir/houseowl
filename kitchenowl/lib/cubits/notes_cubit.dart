import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/note.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/note.dart';

class NotesCubit extends Cubit<NotesCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  List<Note> noteList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  NotesCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingNotesCubitState()) {
    _initialLoad();
    refresh();
    ApiService.getInstance().onNoteUpdate(onNoteUpdate);
  }

  NotesCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingNotesCubitState()) {
    _initialLoad();
    refresh();
  }

  String get query =>
      (state is SearchNotesCubitState)
          ? (state as SearchNotesCubitState).query
          : "";

  void onNoteUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addNote(Note note) async {
    final res = await _transactionHandler.runTransaction(TransactionNoteAdd(
      household: household,
      note: note,
    ));
    await refresh();

    return res;
  }

  Future<bool> updateNote(Note note) async {
    final res = await _transactionHandler
        .runTransaction(TransactionNoteUpdate(
      household: household,
      note: note,
    ));
    await refresh();

    return res;
  }

  Future<bool> deleteNote(Note note) async {
    final res = await _transactionHandler
        .runTransaction(TransactionNoteRemove(
      household: household,
      note: note,
    ));
    await refresh();

    return res;
  }

  /// Delegates the search to the server (ILIKE over title and body) through
  /// the transaction handler. The debouncing lives in the search anchor.
  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> refresh([String? query]) {
    final state = this.state;
    if (state is SearchNotesCubitState) {
      query = query ?? state.query;
    }
    if (_refreshThread == null || query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> _initialLoad() async {
    final notes = await _transactionHandler.runTransaction(
      TransactionNotesGet(household: household),
      forceOffline: true,
    );
    // Don't clobber newer data if a refresh or search already ran.
    if (noteList.isEmpty) {
      noteList = notes;
    }

    if (state is LoadingNotesCubitState && noteList.isNotEmpty) {
      emit(ListNotesCubitState(notes: noteList));
    }
  }

  Future<void> _refresh([String? query]) async {
    if (state is ListNotesCubitState &&
        state is! SearchNotesCubitState &&
        (state as ListNotesCubitState).notes.isEmpty) {
      emit(const LoadingNotesCubitState());
    }
    if (query == null || query.isEmpty) {
      noteList = await _transactionHandler.runTransaction(
        TransactionNotesGet(household: household),
      );
    }

    List<Note> notes = (query != null && query.isNotEmpty)
        ? await _transactionHandler.runTransaction(
            TransactionNotesGet(household: household, query: query),
          )
        : noteList;

    final NotesCubitState newState = (query != null && query.isNotEmpty)
        ? SearchNotesCubitState(notes: notes, query: query)
        : ListNotesCubitState(notes: notes);
    if (_refreshCurrentQuery == query) {
      emit(newState);
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offNoteUpdate(onNoteUpdate);
    super.close();
  }
}

abstract class NotesCubitState extends Equatable {
  const NotesCubitState();

  List<Note> get notes;

  @override
  List<Object?> get props => [];
}

class LoadingNotesCubitState extends NotesCubitState {
  const LoadingNotesCubitState();

  @override
  List<Note> get notes => const [];
}

class ListNotesCubitState extends NotesCubitState {
  final List<Note> notes;

  const ListNotesCubitState({this.notes = const []});

  @override
  List<Object?> get props => <Object?>[...notes];
}

class SearchNotesCubitState extends ListNotesCubitState {
  final String query;

  const SearchNotesCubitState({
    required this.query,
    super.notes,
  });

  @override
  List<Object?> get props => super.props + [query];
}
