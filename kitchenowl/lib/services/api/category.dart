import 'dart:convert';

import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';

extension CategoryApi on ApiService {
  static const baseRoute = '/category';

  Future<List<Category>?> getCategories(Household household) async {
    final res = await get(householdPath(household) + baseRoute);
    if (res.statusCode != 200) return null;

    return List<Category>.from(jsonDecode(res.body).map(
      (e) => Category.fromJson(e),
    ));
  }

  /// Creates a category. Returns the created category (the backend echoes
  /// it), or null on failure — callers can select it immediately.
  Future<Category?> addCategory(Household household, Category category) async {
    final res = await post(
      householdPath(household) + baseRoute,
      jsonEncode(category.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Category.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateCategory(Category category) async {
    final res = await post(
      '$baseRoute/${category.id}',
      jsonEncode(category.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> mergeCategories(Category category, Category other) async {
    final res = await post(
      '$baseRoute/${category.id}',
      jsonEncode({
        "merge_category_id": other.id,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteCategory(Category category) async {
    final res = await delete('$baseRoute/${category.id}');

    return res.statusCode == 200;
  }
}
