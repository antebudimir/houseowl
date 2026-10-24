import 'package:houseowl/models/model.dart';

class ImportSettings extends Model {
  final bool items;
  final bool shoppinglists;

  const ImportSettings({
    this.items = false,
    this.shoppinglists = false,
  });

  ImportSettings copyWith({
    bool? items,
    bool? shoppinglists,
  }) =>
      ImportSettings(
        items: items ?? this.items,
        shoppinglists: shoppinglists ?? this.shoppinglists,
      );

  @override
  List<Object?> get props => [
        items,
        shoppinglists,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "items": items,
        "shoppinglists": shoppinglists,
      };
}
