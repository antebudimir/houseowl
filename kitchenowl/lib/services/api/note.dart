import 'dart:convert';

import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/services/api/api_service.dart';

extension NoteApi on ApiService {
  String noteRoute({Household? household, Note? note}) =>
      "${household != null ? householdPath(household) : ""}/note${note?.id != null ? "/${note!.id}" : ""}";

  Future<List<Note>?> getNotes(Household household, {String? search}) async {
    final res = await get(
      noteRoute(household: household),
      queryParameters: search != null && search.isNotEmpty
          ? {'search': search}
          : null,
    );
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Note.fromJson(e))
        .toList();
  }

  Future<Note?> addNote(Household household, Note note) async {
    final res = await post(
      noteRoute(household: household),
      jsonEncode(note.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Note.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateNote(Note note) async {
    final res = await post(
      noteRoute(note: note),
      jsonEncode(note.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteNote(Note note) async {
    final res = await delete(noteRoute(note: note));

    return res.statusCode == 200;
  }

  void onNoteUpdate(dynamic Function(dynamic) handler) {
    socket.on("note:update", handler);
  }

  void offNoteUpdate(dynamic Function(dynamic) handler) {
    socket.off("note:update", handler);
  }
}
