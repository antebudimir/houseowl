import 'package:houseowl/models/model.dart';

/// The backend stores birthdays without a meaningful year as 1990-01-01
/// (epoch-ms 631152000000). This year must never be displayed.
const int kBirthdayUnknownYear = 1990;

class Person extends Model {
  final int? id;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? notes;
  final String? giftIdea;

  /// UTC midnight of the stored birthday date.
  final DateTime? birthday;
  final int? userId;

  const Person({
    this.id,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.notes,
    this.giftIdea,
    this.birthday,
    this.userId,
  });

  factory Person.fromJson(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      phone: map['phone'],
      email: map['email'],
      notes: map['notes'],
      giftIdea: map['gift_idea'],
      birthday: map['birthday'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['birthday'],
              isUtc: true,
            ),
      userId: map['user_id'],
    );
  }

  bool get hasBirthdayYear => birthday != null &&
      birthday!.year != kBirthdayUnknownYear;

  /// The next occurrence of this person's birthday at local midnight,
  /// ignoring the unknown sentinel year.
  DateTime? nextBirthdayOccurrence([DateTime? now]) {
    if (birthday == null) return null;
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var occurrence = DateTime(now.year, birthday!.month, birthday!.day);
    if (occurrence.isBefore(today)) {
      occurrence = DateTime(now.year + 1, birthday!.month, birthday!.day);
    }

    return occurrence;
  }

  Person copyWith({
    int? id,
    String? name,
    String? role,
    String? phone,
    String? email,
    String? notes,
    String? giftIdea,
    DateTime? birthday,
    int? userId,
  }) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        notes: notes ?? this.notes,
        giftIdea: giftIdea ?? this.giftIdea,
        birthday: birthday ?? this.birthday,
        userId: userId ?? this.userId,
      );

  @override
  List<Object?> get props =>
      [id, name, role, phone, email, notes, giftIdea, birthday, userId];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "role": role,
        "phone": phone,
        "email": email,
        "notes": notes,
        "gift_idea": giftIdea,
        "birthday": birthday?.millisecondsSinceEpoch,
        "user_id": userId,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}