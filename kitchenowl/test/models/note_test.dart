import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/models/tag.dart';

void main() {
  test("Note json roundtrip", () {
    final note = Note.fromJson({
      "id": 5,
      "title": "Wi-Fi",
      "body": "# Wi-Fi\nNetwork: **home**",
      "tags": [
        {"id": 1, "name": "house"},
      ],
    });

    expect(note.title, "Wi-Fi");
    expect(note.body, "# Wi-Fi\nNetwork: **home**");
    expect(note.tags.single, const Tag(id: 1, name: "house"));

    final map = note.toJsonWithId();
    expect(map["id"], 5);
    expect(map["title"], "Wi-Fi");
    // toJson writes tag names (the server resolves ids)...
    expect(map["tags"], ["house"]);

    // ...while fromJson only accepts the full tag objects the server returns.
    final reparsed = Note.fromJson({
      ...map,
      "tags": [
        {"id": 1, "name": "house"},
      ],
    });
    expect(reparsed.title, note.title);
    expect(reparsed.body, note.body);
    expect(reparsed.tags.single, const Tag(id: 1, name: "house"));
  });

  test("Note defaults tolerate a missing body and tags", () {
    final note = Note.fromJson({"id": 1, "title": "Empty"});

    expect(note.body, "");
    expect(note.tags, isEmpty);
    expect(note, Note(id: 1, title: "Empty"));
  });

  test("copyWith replaces only the given fields", () {
    const note = Note(
      id: 2,
      title: "Old",
      body: "Body",
      tags: [Tag(name: "a")],
    );
    final updated = note.copyWith(title: "New", tags: [const Tag(name: "b")]);

    expect(updated.id, 2);
    expect(updated.title, "New");
    expect(updated.body, "Body");
    expect(updated.tags, const [Tag(name: "b")]);
  });
}
