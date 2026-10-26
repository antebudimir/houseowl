import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/member.dart';

void main() {
  test("Document json roundtrip", () {
    final document = Document.fromJson({
      "id": 5,
      "title": "Insurance",
      "notes": "Policy #1234",
      "expires_at": 1893456000000,
      "owner": {"id": 2, "name": "Alice", "username": "alice"},
      "file": {"filename": "policy.pdf"},
    });

    expect(document.title, "Insurance");
    expect(document.notes, "Policy #1234");
    expect(
      document.expiresAt,
      DateTime.fromMillisecondsSinceEpoch(1893456000000, isUtc: true),
    );
    expect(document.owner, isA<Member>());
    expect(document.filename, "policy.pdf");

    final map = document.toJsonWithId();
    expect(map["id"], 5);
    expect(map["title"], "Insurance");
    expect(map["notes"], "Policy #1234");
    expect(map["expires_at"], 1893456000000);
    expect(map["owner_id"], 2);
    expect(map["file_id"], "policy.pdf");

    // fromJson accepts the embedded file/owner objects the server returns.
    final reparsed = Document.fromJson({
      ...map,
      "owner": {"id": 2, "name": "Alice", "username": "alice"},
      "file": {"filename": "policy.pdf"},
    });
    expect(reparsed.title, document.title);
    expect(reparsed.expiresAt, document.expiresAt);
    expect(reparsed.owner, document.owner);
    expect(reparsed.filename, document.filename);
  });

  test("Document tolerates missing optional fields", () {
    final document = Document.fromJson({"id": 1, "title": "Bare"});

    expect(document.notes, isNull);
    expect(document.expiresAt, isNull);
    expect(document.owner, isNull);
    expect(document.filename, isNull);
  });

  test("Expiry helpers classify expired vs expiring soon", () {
    final now = DateTime.parse("2026-01-15T12:00:00Z");
    final expired =
        Document(title: "e", expiresAt: DateTime.parse("2026-01-01T00:00:00Z"));
    final soon =
        Document(title: "s", expiresAt: DateTime.parse("2026-01-20T00:00:00Z"));
    final later =
        Document(title: "l", expiresAt: DateTime.parse("2026-06-01T00:00:00Z"));
    final never = Document(title: "n");

    expect(expired.isExpired(now), isTrue);
    expect(soon.isExpired(now), isFalse);
    expect(soon.expiresWithin(const Duration(days: 30), now), isTrue);
    expect(expired.expiresWithin(const Duration(days: 30), now), isFalse);
    expect(later.expiresWithin(const Duration(days: 30), now), isFalse);
    expect(never.isExpired(now), isFalse);
    expect(never.expiresWithin(const Duration(days: 30), now), isFalse);
  });
}
