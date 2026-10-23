// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/event.dart';
import 'package:kitchenowl/models/person.dart';

void main() {
  test("Event should be equal", () {
    // Given
    final start = DateTime.utc(2026, 11, 1, 10);
    final e1 = Event(name: "Name", start: start, end: start.add(const Duration(hours: 1)));
    final e2 = Event(name: "Name", start: start, end: start.add(const Duration(hours: 1)));
    // Then
    expect(e1 == e2, equals(true));
  });
  test("Event should not be equal", () {
    // Given
    final start = DateTime.utc(2026, 11, 1, 10);
    final e1 = Event(name: "Name", start: start, end: start.add(const Duration(hours: 1)));
    final e2 = Event(name: "Other", start: start, end: start.add(const Duration(hours: 1)));
    // Then
    expect(e1 == e2, equals(false));
  });
  test("Event should de-/serialize", () {
    // Given
    final e = Event(
      id: 1,
      name: "Concert",
      description: "Details",
      location: "Kindergarten",
      start: DateTime.utc(2026, 11, 1, 10),
      end: DateTime.utc(2026, 11, 1, 12),
      allDay: true,
      attendees: [const Person(id: 3, name: "Mom")],
    );
    // When
    final map = e.toJsonWithId();
    // Then
    expect(
      map["start"],
      equals(DateTime.utc(2026, 11, 1, 10).millisecondsSinceEpoch),
    );
    expect(
      map["end"],
      equals(DateTime.utc(2026, 11, 1, 12).millisecondsSinceEpoch),
    );
    expect(map["all_day"], equals(true));
    expect(map["location"], equals("Kindergarten"));
    expect(map["attendees"], equals([3]));
  });
  test("Event should parse from server payload", () {
    // Given
    final startMs =
        DateTime.utc(2026, 11, 1, 10).millisecondsSinceEpoch;
    final e = Event.fromJson({
      "id": 1,
      "name": "Dentist",
      "location": "Main street 1",
      "start": startMs,
      "end": startMs + 3600000,
      "all_day": false,
      "attendees": [
        {"id": 3, "name": "Mom"},
        {"id": 4, "name": "Dad"},
      ],
    });
    // Then
    expect(e.start, equals(DateTime.utc(2026, 11, 1, 10)));
    expect(e.end, equals(DateTime.utc(2026, 11, 1, 11)));
    expect(e.location, equals("Main street 1"));
    expect(e.allDay, isFalse);
    expect(e.attendees.length, equals(2));
    expect(e.attendees.first.name, equals("Mom"));
  });
  test("Event should default missing fields", () {
    // Given
    final startMs =
        DateTime.utc(2026, 11, 1, 10).millisecondsSinceEpoch;
    final e = Event.fromJson({"name": "Name", "start": startMs, "end": startMs});
    // Then
    expect(e.allDay, isFalse);
    expect(e.location, isNull);
    expect(e.attendees, isEmpty);
  });
}
