import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/services/transaction.dart';

import 'local_only_transaction_handler.dart';

Household household = Household(id: 1, name: "Test");

PersonsCubit createSampleCubit() =>
    PersonsCubit.forTesting(LocalOnlyTransactionHandler(), household);

/// Delays the initial cache load so tests can force it to land after newer
/// data has already been seeded or fetched.
class DeferredTransactionHandler extends LocalOnlyTransactionHandler {
  final Completer<List<Person>> initialLoadCompleter = Completer();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    if (forceOffline && !initialLoadCompleter.isCompleted) {
      return initialLoadCompleter.future as Future<T>;
    }

    return super.runTransaction(
      t,
      forceOffline: forceOffline,
      saveTransaction: saveTransaction,
    );
  }

  void completeInitialLoad(List<Person> persons) {
    initialLoadCompleter.complete(persons);
  }
}

void main() {
  test("Refresh emits a list state", () async {
    final cubit = createSampleCubit();
    await cubit.refresh();

    expect(cubit.state, isA<ListPersonsCubitState>());
    expect((cubit.state as ListPersonsCubitState).persons, isEmpty);
    await cubit.close();
  });

  test("Search filters the cached person list by name and role", () async {
    final cubit = createSampleCubit();
    await cubit.refresh();
    cubit.personList = [
      const Person(id: 1, name: "Alice", role: "Plumber"),
      const Person(id: 2, name: "Bob"),
    ];

    await cubit.search("ali");
    var state = cubit.state as SearchPersonsCubitState;
    expect(state.query, "ali");
    expect(state.persons.map((e) => e.name), ["Alice"]);

    await cubit.search("plumb");
    state = cubit.state as SearchPersonsCubitState;
    expect(state.persons.map((e) => e.name), ["Alice"]);

    await cubit.search("zzz");
    expect((cubit.state as SearchPersonsCubitState).persons, isEmpty);

    await cubit.close();
  });

  test("initial load landing late does not clobber newer data", () async {
    final handler = DeferredTransactionHandler();
    final cubit = PersonsCubit.forTesting(handler, household);
    await cubit.refresh();
    cubit.personList = [const Person(id: 1, name: "Alice")];

    // Force the initial cache load to land after newer data exists.
    handler.completeInitialLoad([const Person(id: 99, name: "FromCache")]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.personList.map((e) => e.name), ["Alice"]);
    expect(cubit.state, isA<ListPersonsCubitState>());
    await cubit.close();
  });
}