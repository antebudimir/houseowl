import 'package:houseowl/models/model.dart';
import 'package:houseowl/models/person.dart';

/// An event with optional attendees.
///
/// [start]/[end] are UTC instants (server sends epoch ms) and the interval is
/// half-open [start, end): back-to-back events do not overlap. For all-day
/// events the server stores the UTC instants of the creator's local
/// [midnight, next midnight); the client renders [start]..[end] as a date.
class Event extends Model {
  final int? id;
  final String name;
  final String? description;

  /// Free-form place, e.g. "Kindergarten" or "Community hall".
  final String? location;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final List<Person> attendees;

  const Event({
    this.id,
    required this.name,
    this.description,
    this.location,
    required this.start,
    required this.end,
    this.allDay = false,
    this.attendees = const [],
  });

  factory Event.fromJson(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      location: map['location'],
      start: DateTime.fromMillisecondsSinceEpoch(
        map['start'],
        isUtc: true,
      ),
      end: DateTime.fromMillisecondsSinceEpoch(
        map['end'],
        isUtc: true,
      ),
      allDay: map['all_day'] ?? false,
      attendees: map['attendees'] != null
          ? List.from(map['attendees'])
              .map((e) => Person.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    List<Person>? attendees,
  }) =>
      Event(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        location: location ?? this.location,
        start: start ?? this.start,
        end: end ?? this.end,
        allDay: allDay ?? this.allDay,
        attendees: attendees ?? this.attendees,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        start,
        end,
        allDay,
        attendees,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "location": location,
        "start": start.millisecondsSinceEpoch,
        "end": end.millisecondsSinceEpoch,
        "all_day": allDay,
        "attendees": attendees.map((p) => p.id).toList(),
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
