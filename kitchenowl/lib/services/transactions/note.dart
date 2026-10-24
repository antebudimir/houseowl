import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:houseowl/services/transaction.dart';

/// Lists notes. When [query] is set the list is resolved by the server
/// (`?search=` ILIKE over title and body); offline it falls back to a local
/// filter of the cached notes.
class TransactionNotesGet extends Transaction<List<Note>> {
  final Household household;
  final String? query;

  TransactionNotesGet({
    required this.household,
    this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionNotesGet",
        );

  factory TransactionNotesGet.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionNotesGet(
        household: Household.fromJson(map['household']),
        query: map['query'],
        timestamp: timestamp,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      if (query != null) "query": query,
    });

  @override
  Future<List<Note>> runLocal() async {
    final notes = await MemStorage.getInstance().readNotes(household) ?? [];
    if (query == null || query!.isEmpty) return notes;
    final q = query!.toLowerCase();

    return notes
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<Note>?> runOnline() async {
    final notes = await ApiService.getInstance()
        .getNotes(household, search: query);
    if (notes != null && (query == null || query!.isEmpty)) {
      MemStorage.getInstance().writeNotes(household, notes);
    }

    return notes;
  }
}

class TransactionNoteAdd extends Transaction<bool> {
  final Household household;
  final Note note;

  TransactionNoteAdd({
    required this.household,
    required this.note,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionNoteAdd",
        );

  factory TransactionNoteAdd.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionNoteAdd(
        household: Household.fromJson(map['household']),
        note: Note.fromJson(map['note']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "note": note.toJson(),
    });

  @override
  Future<bool> runLocal() async {
    final notes = await MemStorage.getInstance().readNotes(household) ?? [];
    notes.add(Note(
      title: note.title,
      body: note.body,
      tags: note.tags,
    ));
    MemStorage.getInstance().writeNotes(household, notes);

    return true;
  }

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addNote(household, note) != null;
}

class TransactionNoteUpdate extends Transaction<bool> {
  final Household household;
  final Note note;

  TransactionNoteUpdate({
    required this.household,
    required this.note,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionNoteUpdate",
        );

  factory TransactionNoteUpdate.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionNoteUpdate(
        household: Household.fromJson(map['household']),
        note: Note.fromJson(map['note']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "note": note.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final notes = await MemStorage.getInstance().readNotes(household);
    if (notes == null || note.id == null) return false;
    final int i = notes.indexWhere((e) => e.id == note.id);
    if (i < 0) return false;
    notes[i] = note;
    MemStorage.getInstance().writeNotes(household, notes);

    return true;
  }

  @override
  Future<bool?> runOnline() => ApiService.getInstance().updateNote(note);
}

class TransactionNoteRemove extends Transaction<bool> {
  final Household household;
  final Note note;

  TransactionNoteRemove({
    required this.household,
    required this.note,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionNoteRemove",
        );

  factory TransactionNoteRemove.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionNoteRemove(
        household: Household.fromJson(map['household']),
        note: Note.fromJson(map['note']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "note": note.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final notes = await MemStorage.getInstance().readNotes(household);
    if (notes == null) return false;
    notes.removeWhere((e) => e.id == note.id);
    MemStorage.getInstance().writeNotes(household, notes);

    return true;
  }

  @override
  Future<bool?> runOnline() => ApiService.getInstance().deleteNote(note);
}
