import 'dart:convert';

import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/services/api/api_service.dart';

extension PersonApi on ApiService {
  String personRoute({Household? household, Person? person}) =>
      "${household != null ? householdPath(household) : ""}/person${person?.id != null ? "/${person!.id}" : ""}";

  Future<List<Person>?> getPersons(Household household) async {
    final res = await get(personRoute(household: household));
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Person.fromJson(e))
        .toList();
  }

  Future<Person?> addPerson(Household household, Person person) async {
    final res = await post(
      personRoute(household: household),
      jsonEncode(person.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Person.fromJson(jsonDecode(res.body));
  }

  Future<bool> updatePerson(Person person) async {
    final res = await post(
      personRoute(person: person),
      jsonEncode(person.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deletePerson(Person person) async {
    final res = await delete(personRoute(person: person));

    return res.statusCode == 200;
  }

  void onPersonUpdate(dynamic Function(dynamic) handler) {
    socket.on("person:update", handler);
  }

  void offPersonUpdate(dynamic Function(dynamic) handler) {
    socket.off("person:update", handler);
  }
}