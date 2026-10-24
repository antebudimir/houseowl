// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/enums/task_recurrence_enum.dart';
import 'package:houseowl/models/planned_buy.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/models/tag.dart';

void main() {
  test("Task should be equal", () {
    // Given
    final t1 = Task(id: 1, name: "Name");
    final t2 = Task(id: 1, name: "Name");
    // Then
    expect(t1 == t2, equals(true));
  });
  test("Task should not be equal", () {
    // Given
    final t1 = Task(id: 1, name: "Name");
    final t2 = Task(id: 1, name: "Other Name");
    // Then
    expect(t1 == t2, equals(false));
  });
  test("Task should de-/serialize", () {
    // Given
    final t = Task(
      id: 1,
      name: "Name",
      description: "Details",
      priority: 2,
      recurrence: TaskRecurrence.biweekly,
      dueDate: DateTime(2026, 11, 1),
      assigneeId: 3,
      buyId: 4,
      tags: [Tag(name: "fix")],
    );
    // When
    final map = t.toJsonWithId();
    // Then
    expect(map["due_date"], equals("2026-11-01"));
    expect(map["recurrence"], equals("biweekly"));
    expect(map["priority"], equals(2));
    expect(map["tags"], equals(["fix"]));
    expect(map["assignee_id"], equals(3));
    expect(map["buy_id"], equals(4));
  });
  test("Task should parse from server payload", () {
    // Given
    final t = Task.fromJson({
      "id": 1,
      "name": "Name",
      "status": "done",
      "priority": 1,
      "recurrence": "monthly",
      "due_date": "2026-02-28",
      "completed_at": 1792714660680,
      "buy": {"id": 4, "name": "paint"},
      "tags": [
        {"id": 2, "name": "fix"},
      ],
    });
    // Then
    expect(t.isDone, equals(true));
    expect(t.recurrence, equals(TaskRecurrence.monthly));
    expect(t.dueDate, equals(DateTime(2026, 2, 28)));
    expect(t.completedAt, isNotNull);
    expect(t.buy, isA<PlannedBuy>());
    expect(t.tags.first.name, equals("fix"));
  });
  test("Task should default unknown recurrence to none", () {
    // Given
    final t = Task.fromJson({"name": "Name", "recurrence": "hourly"});
    // Then
    expect(t.recurrence, equals(TaskRecurrence.none));
  });
}
