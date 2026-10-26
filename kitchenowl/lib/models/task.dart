import 'package:houseowl/enums/task_recurrence_enum.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/model.dart';
import 'package:houseowl/models/planned_buy.dart';
import 'package:houseowl/models/tag.dart';

class Task extends Model {
  final int? id;
  final String name;
  final String? description;
  final String status;
  final int priority;
  final TaskRecurrence recurrence;

  /// Bare calendar date (server sends "yyyy-MM-dd"); no time component.
  final DateTime? dueDate;

  /// Server-stamped when the task is completed.
  final DateTime? completedAt;
  final int? assigneeId;
  final Member? assignee;
  final int? buyId;
  final PlannedBuy? buy;
  final List<Tag> tags;

  const Task({
    this.id,
    required this.name,
    this.description,
    this.status = 'open',
    this.priority = 0,
    this.recurrence = TaskRecurrence.none,
    this.dueDate,
    this.completedAt,
    this.assigneeId,
    this.assignee,
    this.buyId,
    this.buy,
    this.tags = const [],
  });

  factory Task.fromJson(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 0,
      recurrence: map['recurrence'] == null
          ? TaskRecurrence.none
          : TaskRecurrence.parse(map['recurrence']),
      dueDate:
          map['due_date'] == null ? null : DateTime.tryParse(map['due_date']),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['completed_at'],
              isUtc: true,
            ),
      assigneeId: map['assignee_id'],
      assignee:
          map['assignee'] == null ? null : Member.fromJson(map['assignee']),
      buyId: map['buy_id'],
      buy: map['buy'] == null ? null : PlannedBuy.fromJson(map['buy']),
      tags: map['tags'] != null
          ? List.from(map['tags'])
              .map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  bool get isDone => status == 'done';

  Task copyWith({
    int? id,
    String? name,
    String? description,
    String? status,
    int? priority,
    TaskRecurrence? recurrence,
    DateTime? dueDate,
    DateTime? completedAt,
    int? assigneeId,
    Member? assignee,
    int? buyId,
    PlannedBuy? buy,
    List<Tag>? tags,
  }) =>
      Task(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        recurrence: recurrence ?? this.recurrence,
        dueDate: dueDate ?? this.dueDate,
        completedAt: completedAt ?? this.completedAt,
        assigneeId: assigneeId ?? this.assigneeId,
        assignee: assignee ?? this.assignee,
        buyId: buyId ?? this.buyId,
        buy: buy ?? this.buy,
        tags: tags ?? this.tags,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        status,
        priority,
        recurrence,
        dueDate,
        completedAt,
        assigneeId,
        assignee,
        buyId,
        buy,
        tags,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "status": status,
        "priority": priority,
        "recurrence": recurrence.name,
        // ISO date string only — never a timestamp with a time zone.
        "due_date":
            dueDate == null ? null : dueDate!.toIso8601String().substring(0, 10),
        "assignee_id": assigneeId,
        "buy_id": buyId,
        "tags": tags.map((e) => e.name).toList(),
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
