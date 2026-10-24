import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' as foundation;
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/models/tag.dart';
import 'package:houseowl/models/user.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

class TempStorage {
  static TempStorage? _instance;

  TempStorage._internal();
  static TempStorage getInstance() {
    _instance ??= TempStorage._internal();

    return _instance!;
  }

  Future<String> get _localPath async {
    return pathProvider.getApplicationCacheDirectory().then((dir) => dir.path);
  }

  Future<File> get _localUserFile async {
    final path = await _localPath;

    return File('$path/user.json');
  }

  Future<File> get _localHouseholdsFile async {
    final path = await _localPath;

    return File('$path/households.json');
  }

  Future<File> _localShoppingListsFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-shoppinglists.json');
  }

  Future<File> _localPersonsFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-persons.json');
  }

  Future<File> _localCategoryFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-categories.json');
  }

  Future<File> _localTagsFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-tags.json');
  }

  Future<void> clearAll() async {
    await readHouseholds().then(
      (value) => Future.wait(
        value?.map((household) async {
              await Future.wait([
                clearShoppingLists(household),
                clearPersons(household),
                clearNotes(household),
                clearCategories(household),
                clearTags(household),
              ]);
            }).toList() ??
            [],
      ),
    );

    await Future.wait([
      clearUser(),
      clearHouseholds(),
    ]);
  }

  Future<User?> readUser() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localUserFile;
        final String content = await file.readAsString();

        return User.fromJson(json.decode(content));
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearUser() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localUserFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeUser(User user) async {
    if (!foundation.kIsWeb) {
      final file = await _localUserFile;
      await file.writeAsString(json.encode(user.toJsonWithId()));
    }
  }

  Future<List<ShoppingList>?> readShoppingLists(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localShoppingListsFile(household);
        final String content = await file.readAsString();
        List list = json.decode(content);

        return list.map((e) => ShoppingList.fromJson(e)).toList();
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearShoppingLists(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localShoppingListsFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeShoppingLists(
    Household household,
    List<ShoppingList> shoppingLists,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localShoppingListsFile(household);
      await file.writeAsString(
        json.encode(shoppingLists.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<List<Person>?> readPersons(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localPersonsFile(household);
        final String content = await file.readAsString();

        return List<Person>.from(
          json.decode(content).map((e) => Person.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writePersons(Household household, List<Person> persons) async {
    if (!foundation.kIsWeb) {
      final file = await _localPersonsFile(household);
      await file.writeAsString(
        json.encode(persons.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearPersons(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localPersonsFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<File> _localNotesFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-notes.json');
  }

  Future<List<Note>?> readNotes(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localNotesFile(household);
        final String content = await file.readAsString();

        return List<Note>.from(
          json.decode(content).map((e) => Note.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeNotes(Household household, List<Note> notes) async {
    if (!foundation.kIsWeb) {
      final file = await _localNotesFile(household);
      await file.writeAsString(
        json.encode(notes.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearNotes(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localNotesFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Category>?> readCategories(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localCategoryFile(household);
        final String content = await file.readAsString();

        return List<Category>.from(
          json.decode(content).map((e) => Category.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeCategories(
    Household household,
    List<Category> categories,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localCategoryFile(household);
      await file.writeAsString(
        json.encode(categories.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearCategories(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localCategoryFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<Set<Tag>?> readTags(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localTagsFile(household);
        final String content = await file.readAsString();

        return Set<Tag>.from(
          json.decode(content).map((e) => Tag.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeTags(
    Household household,
    Set<Tag> tags,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localTagsFile(household);
      await file.writeAsString(
        json.encode(tags.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearTags(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localTagsFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Household>?> readHouseholds() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localHouseholdsFile;
        final String content = await file.readAsString();

        return List<Household>.from(
          json.decode(content).map((e) => Household.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeHouseholds(List<Household> households) async {
    if (!foundation.kIsWeb) {
      final file = await _localHouseholdsFile;
      await file.writeAsString(
        json.encode(households.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearHouseholds() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localHouseholdsFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
