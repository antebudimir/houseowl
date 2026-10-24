import 'package:houseowl/models/model.dart';
import 'package:houseowl/models/user.dart';

class Report extends Model {
  final int? id;
  final String? description;
  final User? user;
  final User? createdBy;
  final DateTime? createdAt;

  const Report({
    this.id,
    this.description,
    this.user,
    this.createdBy,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      description: map['description'],
      user: map.containsKey("user") ? User.fromJson(map['user']) : null,
      createdBy: map.containsKey("created_by")
          ? User.fromJson(map['created_by'])
          : null,
      createdAt: map.containsKey("created_at")
          ? DateTime.fromMillisecondsSinceEpoch(map["created_at"], isUtc: true)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        user,
        createdBy,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "description": description,
        "user": user?.toJson(),
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "created_by": createdBy?.toJsonWithId(),
      if (createdAt != null) "created_at": createdAt?.millisecondsSinceEpoch,
    });
}
