// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/models/shoppinglist.dart';

void main() {
  test("ShoppingList should be equal", () {
    // Given
    final s1 = ShoppingList(id: 1, name: "Name", isDefault: true);
    final s2 = ShoppingList(id: 1, name: "Name", isDefault: true);
    // Then
    expect(s1 == s2, equals(true));
  });
  test("ShoppingList should not be equal", () {
    // Given
    final s1 = ShoppingList(id: 1, name: "Name", isDefault: true);
    final s2 = ShoppingList(id: 1, name: "Name", isDefault: false);
    // Then
    expect(s1 == s2, equals(false));
  });
  test("ShoppingList should de-/serialize the default flag", () {
    // Given
    final s = ShoppingList(id: 1, name: "Name", isDefault: true);
    // When
    final actual = ShoppingList.fromJson(
      s.toJsonWithId()..addAll({"default": true}),
    );
    // Then
    expect(actual.isDefault, equals(true));
    expect(actual.name, equals("Name"));
  });
  test("ShoppingList should tolerate a missing default flag", () {
    // When
    final actual = ShoppingList.fromJson({"id": 1, "name": "Name"});
    // Then
    expect(actual.isDefault, isNull);
  });
}