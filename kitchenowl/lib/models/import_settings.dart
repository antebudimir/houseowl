import 'package:kitchenowl/models/model.dart';

class ImportSettings extends Model {
  final bool items;
  final bool expenses;
  final bool shoppinglists;

  const ImportSettings({
    this.items = false,
    this.expenses = false,
    this.shoppinglists = false,
  });

  ImportSettings copyWith({
    bool? items,
    bool? expenses,
    bool? shoppinglists,
  }) =>
      ImportSettings(
        items: items ?? this.items,
        expenses: expenses ?? this.expenses,
        shoppinglists: shoppinglists ?? this.shoppinglists,
      );

  @override
  List<Object?> get props => [
        items,
        expenses,
        shoppinglists,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "items": items,
        "expenses": expenses,
        "shoppinglists": shoppinglists,
      };
}
