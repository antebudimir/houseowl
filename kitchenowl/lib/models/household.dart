import 'package:collection/collection.dart';
import 'package:houseowl/enums/views_enum.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/model.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/models/user.dart';

class Household extends Model {
  final int id;
  final String name;
  final String? image;
  final String? imageHash;
  final String? language;
  final List<ViewsEnum>? viewOrdering;
  final List<ViewsEnum>? hiddenViews;
  final List<Member>? member;
  final ShoppingList? defaultShoppingList;
  final String? description;
  final String? link;
  final bool verified;

  const Household({
    required this.id,
    this.name = '',
    this.image,
    this.imageHash,
    this.language,
    this.viewOrdering,
    this.hiddenViews,
    this.member,
    this.defaultShoppingList,
    this.description,
    this.link,
    this.verified = false,
  });

  factory Household.fromJson(Map<String, dynamic> map) {
    List<ViewsEnum> viewOrdering = ViewsEnum.values;
    if (map.containsKey('view_ordering')) {
      viewOrdering = ViewsEnum.addMissing(List.from(map['view_ordering']
          .map((e) => ViewsEnum.parse(e))
          .where((e) => e != null)));
    }

    List<Member> member = const [];
    if (map.containsKey('member')) {
      member = List.from(map['member'].map((e) => Member.fromJson(e)));
    }

    List<ViewsEnum>? hiddenViews;
    if (map.containsKey('hidden_views')) {
      hiddenViews = List.from(map['hidden_views']
          .map((e) => ViewsEnum.parse(e))
          .where((e) => e != null));
    }

    return Household(
      id: map['id'],
      name: map['name'],
      image: map['photo'],
      imageHash: map['photo_hash'],
      language: map['language'],
      description: map['description'],
      link: map['link'],
      verified: map['verified'] ?? false,
      viewOrdering: viewOrdering,
      hiddenViews: hiddenViews,
      member: member,
      defaultShoppingList: map.containsKey("default_shopping_list")
          ? ShoppingList.fromJson(map['default_shopping_list'])
          : null,
    );
  }

  Household copyWith({
    String? name,
    String? image,
    String? language,
    String? description,
    String? link,
    bool? verified,
    List<ViewsEnum>? viewOrdering,
    List<ViewsEnum>? hiddenViews,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        image: image ?? this.image,
        imageHash: imageHash,
        language: language ?? this.language,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        hiddenViews: hiddenViews ?? this.hiddenViews,
        description: description ?? this.description,
        link: link ?? this.link,
        verified: verified ?? this.verified,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        imageHash,
        language,
        viewOrdering,
        hiddenViews,
        member,
        defaultShoppingList,
        description,
        link,
        verified,
      ];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      "name": name,
      "verified": verified,
    };
    if (image != null) {
      data['photo'] = image;
    }
    if (language != null) {
      data['language'] = language;
    }
    if (viewOrdering != null) {
      data['view_ordering'] = viewOrdering!.map((e) => e.toString()).toList()
        ..remove(ViewsEnum.more.toString());
    }
    if (hiddenViews != null) {
      data['hidden_views'] = hiddenViews!.map((e) => e.toString()).toList();
    }
    if (description != null) {
      data['description'] = description;
    }
    if (link != null) {
      data['link'] = link;
    }

    return data;
  }

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      if (member?.isNotEmpty ?? false)
        "member": member!.map((e) => e.toJsonWithId()).toList(),
      if (defaultShoppingList != null)
        "default_shopping_list": defaultShoppingList!.toJsonWithId(),
      if (imageHash != null) "photo_hash": imageHash,
    });

  bool hasAdminRights(User user) => (member
          ?.firstWhereOrNull(
            (e) => user.id == e.id,
          )
          ?.hasAdminRights() ??
      false);
}
