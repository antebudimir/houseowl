import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';

class ShoppingList extends Model {
  final int? id;
  final String name;
  final bool? isDefault;
  final List<ShoppinglistItem> items;
  final List<ItemWithDescription> recentItems;

  const ShoppingList({
    this.id,
    required this.name,
    this.isDefault,
    this.items = const [],
    this.recentItems = const [],
  });

  factory ShoppingList.fromJson(Map<String, dynamic> map) {
    List<ShoppinglistItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => ShoppinglistItem.fromJson(e)));
    }
    List<ItemWithDescription> recentItems = const [];
    if (map.containsKey('recentItems')) {
      recentItems = List.from(
          map['recentItems'].map((e) => ItemWithDescription.fromJson(e)));
    }

    return ShoppingList(
      id: map['id'],
      name: map['name'],
      isDefault: map['default'],
      items: items,
      recentItems: recentItems,
    );
  }

  ShoppingList copyWith({
    String? name,
    bool? isDefault,
    List<ShoppinglistItem>? items,
    List<ItemWithDescription>? recentItems,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        isDefault: isDefault ?? this.isDefault,
        items: items ?? this.items,
        recentItems: recentItems ?? this.recentItems,
      );

  @override
  List<Object?> get props => [id, name, isDefault, items, recentItems];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "items": items.map((e) => e.toJsonWithId()).toList(),
      "recentItems": recentItems.map((e) => e.toJsonWithId()).toList(),
    });
}
