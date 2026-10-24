import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/models/tag.dart';
import 'package:houseowl/models/user.dart';
import 'package:houseowl/services/storage/temp_storage.dart';

/// An in memory storage for cached households.
/// Optionally, can write and read (on initial load) the data from a persistent storage.
class MemStorage {
  static MemStorage? _instance;
  final TempStorage? persistentStorage;

  MemStorage._internal(this.persistentStorage);
  static MemStorage getInstance() {
    _instance ??= MemStorage._internal(TempStorage.getInstance());

    return _instance!;
  }

  Future<void> clearAll() async {
    persistentStorage?.clearAll();
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

  User? _user;

  Future<User?> readUser() async {
    if (persistentStorage != null && _user == null) {
      _user = await persistentStorage!.readUser();
    }
    return _user;
  }

  Future<void> clearUser() async {
    _user = null;
  }

  Future<void> writeUser(User user) async {
    persistentStorage?.writeUser(user);
    _user = user;
  }

  Map<int, List<ShoppingList>?> _shoppinglists = {};

  Future<List<ShoppingList>?> readShoppingLists(Household household) async {
    if (persistentStorage != null && _shoppinglists[household.id] == null) {
      _shoppinglists[household.id] =
          await persistentStorage!.readShoppingLists(household);
    }
    if (_shoppinglists[household.id] == null) return null;
    return List.of(_shoppinglists[household.id]!);
  }

  Future<void> clearShoppingLists(Household household) async {
    _shoppinglists = {};
  }

  Future<void> writeShoppingLists(
    Household household,
    List<ShoppingList> shoppingLists,
  ) async {
    persistentStorage?.writeShoppingLists(household, shoppingLists);
    _shoppinglists[household.id] = shoppingLists;
  }

  Map<int, List<Person>?> _persons = {};

  Future<List<Person>?> readPersons(Household household) async {
    if (persistentStorage != null && _persons[household.id] == null) {
      _persons[household.id] =
          await persistentStorage!.readPersons(household);
    }
    if (_persons[household.id] == null) return null;
    return List.of(_persons[household.id]!);
  }

  Future<void> writePersons(Household household, List<Person> persons) async {
    persistentStorage?.writePersons(household, persons);
    _persons[household.id] = persons;
  }

  Future<void> clearPersons(Household household) async {
    _persons = {};
  }

  Map<int, List<Note>?> _notes = {};

  Future<List<Note>?> readNotes(Household household) async {
    if (persistentStorage != null && _notes[household.id] == null) {
      _notes[household.id] = await persistentStorage!.readNotes(household);
    }
    if (_notes[household.id] == null) return null;
    return List.of(_notes[household.id]!);
  }

  Future<void> writeNotes(Household household, List<Note> notes) async {
    persistentStorage?.writeNotes(household, notes);
    _notes[household.id] = notes;
  }

  Future<void> clearNotes(Household household) async {
    _notes = {};
  }

  Map<int, List<Category>?> _categories = {};

  Future<List<Category>?> readCategories(Household household) async {
    if (persistentStorage != null && _categories[household.id] == null) {
      _categories[household.id] =
          await persistentStorage!.readCategories(household);
    }
    if (_categories[household.id] == null) return null;
    return List.of(_categories[household.id]!);
  }

  Future<void> writeCategories(
    Household household,
    List<Category> categories,
  ) async {
    persistentStorage?.writeCategories(household, categories);
    _categories[household.id] = categories;
  }

  Future<void> clearCategories(Household household) async {
    _categories = {};
  }

  Map<int, Set<Tag>?> _tags = {};

  Future<Set<Tag>?> readTags(Household household) async {
    if (persistentStorage != null && _tags[household.id] == null) {
      _tags[household.id] = await persistentStorage!.readTags(household);
    }
    if (_tags[household.id] == null) return null;
    return Set.of(_tags[household.id]!);
  }

  Future<void> writeTags(
    Household household,
    Set<Tag> tags,
  ) async {
    persistentStorage?.writeTags(household, tags);
    _tags[household.id] = tags;
  }

  Future<void> clearTags(Household household) async {
    _tags = {};
  }

  List<Household>? _households;

  Future<List<Household>?> readHouseholds() async {
    if (persistentStorage != null && _households == null) {
      _households = await persistentStorage!.readHouseholds();
    }
    if (_households == null) return null;
    return List.of(_households!);
  }

  Future<void> writeHouseholds(List<Household> households) async {
    persistentStorage?.writeHouseholds(households);
    _households = households;
  }

  Future<void> clearHouseholds() async {
    _households = null;
  }
}
