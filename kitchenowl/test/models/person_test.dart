import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/person.dart';

void main() {
  test("Person json roundtrip", () {
    final person = Person.fromJson({
      "id": 3,
      "name": "Alice",
      "role": "Plumber",
      "phone": "12345",
      "email": "alice@example.com",
      "notes": "Met at the hardware store",
      "birthday": 631152000000,
      "user_id": 7,
    });

    expect(person.name, "Alice");
    expect(person.birthday, DateTime.utc(1990, 1, 1));
    expect(person.hasBirthdayYear, isFalse);
    expect(person.userId, 7);

    final map = person.toJsonWithId();
    expect(map["id"], 3);
    expect(map["name"], "Alice");
    expect(map["birthday"], 631152000000);
    expect(map["user_id"], 7);

    final reparsed = Person.fromJson(map);
    expect(reparsed, person);
  });

  test("Known birthday year is preserved", () {
    final person = Person.fromJson({
      "name": "Bob",
      "birthday": 694224000000, // 1992-01-01 UTC
    });

    expect(person.hasBirthdayYear, isTrue);
    expect(person.birthday, DateTime.utc(1992, 1, 1));
  });

  test("nextBirthdayOccurrence ignores the sentinel year", () {
    final sentinel = Person.fromJson({
      "name": "Carol",
      "birthday": 631152000000, // 1990-01-01 (unknown year)
    });
    final known = Person.fromJson({
      "name": "Dave",
      "birthday": DateTime.utc(1980, 3, 10).millisecondsSinceEpoch,
    });

    final nextSentinel = sentinel.nextBirthdayOccurrence(
      DateTime(2024, 6, 1),
    );
    expect(nextSentinel!.year, 2025);
    expect(nextSentinel.month, 1);
    expect(nextSentinel.day, 1);

    final nextKnown = known.nextBirthdayOccurrence(DateTime(2024, 6, 1));
    expect(nextKnown!.year, 2025);
    expect(nextKnown.month, 3);
    expect(nextKnown.day, 10);

    // Same-day birthdays are returned as today.
    final today = known.nextBirthdayOccurrence(DateTime(2024, 3, 10, 12));
    expect(today, DateTime(2024, 3, 10));

    expect(Person(name: "Eve").nextBirthdayOccurrence(), isNull);
  });
}