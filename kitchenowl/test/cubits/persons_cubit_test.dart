import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/cubits/persons_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/person.dart';

import 'local_only_transaction_handler.dart';

Household household = Household(id: 1, name: "Test");

PersonsCubit createSampleCubit() =>
    PersonsCubit.forTesting(LocalOnlyTransactionHandler(), household);

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
}