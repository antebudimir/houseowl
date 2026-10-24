import 'package:houseowl/models/model.dart';
import 'package:houseowl/models/tag.dart';

class Note extends Model {
  final int? id;
  final String title;
  final String body;
  final List<Tag> tags;

  const Note({
    this.id,
    this.title = '',
    this.body = '',
    this.tags = const [],
  });

  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      body: map['body'] ?? '',
      tags: map['tags'] != null
          ? List.from(map['tags'])
              .map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? body,
    List<Tag>? tags,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
      );

  @override
  List<Object?> get props => [id, title, body, tags];

  @override
  String toString() => "Note($id, $title)";

  @override
  Map<String, dynamic> toJson() => {
        "title": title,
        "body": body,
        "tags": tags.map((e) => e.name).toList(),
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
