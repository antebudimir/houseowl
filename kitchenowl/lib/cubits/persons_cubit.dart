import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/person.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/person.dart';

class PersonsCubit extends Cubit<PersonsCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  List<Person> personList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  PersonsCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingPersonsCubitState()) {
    _initialLoad();
    refresh();
    ApiService.getInstance().onPersonUpdate(onPersonUpdate);
  }

  PersonsCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingPersonsCubitState()) {
    _initialLoad();
    refresh();
  }

  String get query => (state is SearchPersonsCubitState)
      ? (state as SearchPersonsCubitState).query
      : "";

  void onPersonUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addPerson(Person person) async {
    final res = await _transactionHandler.runTransaction(TransactionPersonAdd(
      household: household,
      person: person,
    ));
    await refresh();

    return res;
  }

  Future<bool> updatePerson(Person person) async {
    final res = await _transactionHandler
        .runTransaction(TransactionPersonUpdate(
      household: household,
      person: person,
    ));
    await refresh();

    return res;
  }

  Future<bool> deletePerson(Person person) async {
    final res = await _transactionHandler
        .runTransaction(TransactionPersonRemove(
      household: household,
      person: person,
    ));
    await refresh();

    return res;
  }

  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> refresh([String? query]) {
    final state = this.state;
    if (state is SearchPersonsCubitState) {
      query = query ?? state.query;
    }
    if (_refreshThread == null || query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> _initialLoad() async {
    final persons = await _transactionHandler.runTransaction(
      TransactionPersonsGet(household: household),
      forceOffline: true,
    );
    // Don't clobber newer data if a refresh or search already ran.
    if (personList.isEmpty) {
      personList = persons;
    }

    if (state is LoadingPersonsCubitState && personList.isNotEmpty) {
      emit(ListPersonsCubitState(persons: personList));
    }
  }

  Future<void> _refresh([String? query]) async {
    if (state is ListPersonsCubitState &&
        state is! SearchPersonsCubitState &&
        (state as ListPersonsCubitState).persons.isEmpty) {
      emit(const LoadingPersonsCubitState());
    }
    if (query == null || query.isEmpty) {
      personList = await _transactionHandler.runTransaction(
        TransactionPersonsGet(household: household),
      );
    }

    List<Person> persons = personList;
    if (query != null && query.isNotEmpty) {
      final normalizedQuery = query.trim().toLowerCase();
      persons = persons
          .where((e) =>
              e.name.toLowerCase().contains(normalizedQuery) ||
              (e.role ?? "").toLowerCase().contains(normalizedQuery))
          .toList();
    }

    final PersonsCubitState newState = (query != null && query.isNotEmpty)
        ? SearchPersonsCubitState(persons: persons, query: query)
        : ListPersonsCubitState(persons: persons);
    if (_refreshCurrentQuery == query) {
      emit(newState);
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offPersonUpdate(onPersonUpdate);
    super.close();
  }
}

abstract class PersonsCubitState extends Equatable {
  const PersonsCubitState();

  List<Person> get persons;

  @override
  List<Object?> get props => [];
}

class LoadingPersonsCubitState extends PersonsCubitState {
  const LoadingPersonsCubitState();

  @override
  List<Person> get persons => const [];
}

class ListPersonsCubitState extends PersonsCubitState {
  final List<Person> persons;

  const ListPersonsCubitState({this.persons = const []});

  @override
  List<Object?> get props => <Object?>[...persons];
}

class SearchPersonsCubitState extends ListPersonsCubitState {
  final String query;

  const SearchPersonsCubitState({
    required this.query,
    super.persons,
  });

  @override
  List<Object?> get props => super.props + [query];
}