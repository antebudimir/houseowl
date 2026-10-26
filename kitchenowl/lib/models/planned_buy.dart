import 'package:houseowl/enums/buy_status.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/model.dart';

class PlannedBuy extends Model {
  final int? id;
  final String name;
  final BuyStatus status;
  final int priority;
  final String? category;
  final DateTime? targetDate;

  /// Price paid once the buy has been acquired.
  final num? actualPrice;

  /// Server-stamped when the status transitions to acquired.
  final DateTime? acquiredAt;
  final int? assigneeId;
  final Member? assignee;

  const PlannedBuy({
    this.id,
    required this.name,
    this.status = BuyStatus.idea,
    this.priority = 0,
    this.category,
    this.targetDate,
    this.actualPrice,
    this.acquiredAt,
    this.assigneeId,
    this.assignee,
  });

  factory PlannedBuy.fromJson(Map<String, dynamic> map) {
    final dynamic actualPrice = map['actual_price'];

    return PlannedBuy(
      id: map['id'],
      name: map['name'],
      status: map['status'] == null
          ? BuyStatus.idea
          : BuyStatus.parse(map['status']),
      priority: map['priority'] ?? 0,
      category: map['category'],
      targetDate: map['target_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['target_date'],
              isUtc: true,
            ),
      actualPrice: actualPrice == null
          ? null
          : ((actualPrice as num).toDouble() * 100).round().toDouble() / 100,
      acquiredAt: map['acquired_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['acquired_at'],
              isUtc: true,
            ),
      assigneeId: map['assignee_id'],
      assignee:
          map['assignee'] == null ? null : Member.fromJson(map['assignee']),
    );
  }

  bool get isAcquired => status == BuyStatus.acquired;

  PlannedBuy copyWith({
    int? id,
    String? name,
    BuyStatus? status,
    int? priority,
    String? category,
    DateTime? targetDate,
    num? actualPrice,
    DateTime? acquiredAt,
    int? assigneeId,
    Member? assignee,
  }) =>
      PlannedBuy(
        id: id ?? this.id,
        name: name ?? this.name,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        targetDate: targetDate ?? this.targetDate,
        actualPrice: actualPrice ?? this.actualPrice,
        acquiredAt: acquiredAt ?? this.acquiredAt,
        assigneeId: assigneeId ?? this.assigneeId,
        assignee: assignee ?? this.assignee,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        priority,
        category,
        targetDate,
        actualPrice,
        acquiredAt,
        assigneeId,
        assignee,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "status": status.name,
        "priority": priority,
        "category": category,
        "target_date": targetDate?.millisecondsSinceEpoch,
        "actual_price": actualPrice,
        "assignee_id": assigneeId,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
