import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/cubits/notes_cubit.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/note.dart';
import 'package:houseowl/models/tag.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:houseowl/services/transaction.dart';

import 'local_only_transaction_handler.dart';

Household household = Household(id: 1, name: "Test");

final sampleNotes = const [
  Note(id: 1, title: "Wi-Fi", body: "# Wi-Fi\npassword: hunter2"),
  Note(id: 2, title: "Bin day", body: "Tuesday, blue bin"),
];

NotesCubit createSampleCubit() =>
    NotesCubit.forTesting(LocalOnlyTransactionHandler(), household);

/// Delays the initial cache load so tests can force it to land after newer
/// data has already been seeded or fetched.
class DeferredTransactionHandler extends LocalOnlyTransactionHandler {
  final Completer<List<Note>> initialLoadCompleter = Completer();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    if (forceOffline && !initialLoadCompleter.isCompleted) {
      return initialLoadCompleter.future as Future<T>;
    }

    return super.runTransaction(
      t,
      forceOffline: forceOffline,
      saveTransaction: saveTransaction,
    );
  }

  void completeInitialLoad(List<Note> notes) {
    initialLoadCompleter.complete(notes);
  }
}

void main() {
  // Seeding must happen inside the FakeAsync zone so the fire-and-forget
  // persistent write of writeNotes is never awaited: its path_provider
  // future never completes in tests. The in-memory map is set synchronously,
  // so no pump is needed.
  void pumpSeeded(List<Note> notes) {
    MemStorage.getInstance().writeNotes(household, notes);
  }

  testWidgets("Refresh emits the cached note list", (tester) async {
    pumpSeeded(sampleNotes);
    final cubit = createSampleCubit();
    await cubit.refresh();

    expect(cubit.state, isA<ListNotesCubitState>());
    expect((cubit.state as ListNotesCubitState).notes, sampleNotes);
    await cubit.close();
  });

  testWidgets("Search runs through the transaction handler and matches title/body",
      (tester) async {
    pumpSeeded(sampleNotes);
    final cubit = createSampleCubit();

    await cubit.search("wi-fi");
    var state = cubit.state as SearchNotesCubitState;
    expect(state.query, "wi-fi");
    expect(state.notes.map((e) => e.title), ["Wi-Fi"]);

    await cubit.search("bin");
    state = cubit.state as SearchNotesCubitState;
    expect(state.notes.map((e) => e.title), ["Bin day"]);

    // Search hits the markdown body, not just the title.
    await cubit.search("hunter2");
    expect(
      (cubit.state as SearchNotesCubitState).notes.map((e) => e.title),
      ["Wi-Fi"],
    );

    await cubit.search("zzz");
    expect((cubit.state as SearchNotesCubitState).notes, isEmpty);

    // Clearing the query returns the full list.
    await cubit.search("");
    expect(cubit.state, isA<ListNotesCubitState>());
    expect((cubit.state as ListNotesCubitState).notes, sampleNotes);

    await cubit.close();
  });

  testWidgets("addNote persists offline and refreshes", (tester) async {
    pumpSeeded(sampleNotes);
    final cubit = createSampleCubit();

    final res = await cubit.addNote(const Note(
      title: "New",
      body: "Body",
      tags: [Tag(name: "house")],
    ));
    expect(res, isTrue);

    final notes = (cubit.state as ListNotesCubitState).notes;
    expect(notes.map((e) => e.title), contains("New"));
    expect(
      notes.firstWhere((e) => e.title == "New").tags,
      const [Tag(name: "house")],
    );

    await cubit.close();
  });

  testWidgets("updateNote replaces the cached note", (tester) async {
    pumpSeeded(sampleNotes);
    final cubit = createSampleCubit();

    final res = await cubit.updateNote(
      sampleNotes[0].copyWith(body: "new password"),
    );
    expect(res, isTrue);
    expect(
      (cubit.state as ListNotesCubitState)
          .notes
          .firstWhere((e) => e.id == 1)
          .body,
      "new password",
    );

    await cubit.close();
  });

  testWidgets("deleteNote removes the cached note", (tester) async {
    pumpSeeded(sampleNotes);
    final cubit = createSampleCubit();

    final res = await cubit.deleteNote(sampleNotes[0]);
    expect(res, isTrue);
    expect(
      (cubit.state as ListNotesCubitState).notes.map((e) => e.title),
      ["Bin day"],
    );

    await cubit.close();
  });

  testWidgets("initial load landing late does not clobber newer data",
      (tester) async {
    pumpSeeded(sampleNotes);
    final handler = DeferredTransactionHandler();
    final cubit = NotesCubit.forTesting(handler, household);
    await cubit.refresh();
    cubit.noteList = [sampleNotes[0]];

    // Force the initial cache load to land after newer data exists.
    handler.completeInitialLoad([const Note(id: 99, title: "FromCache")]);
    await tester.pump();

    expect(cubit.noteList.map((e) => e.title), ["Wi-Fi"]);
    expect(cubit.state, isA<ListNotesCubitState>());
    await cubit.close();
  });
}
