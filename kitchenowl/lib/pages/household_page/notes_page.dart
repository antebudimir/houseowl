import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/notes_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/note.dart';

import 'note_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<NotesCubit>(context);

    return SafeArea(
      child: BlocBuilder<NotesCubit, NotesCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingNotesCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.notes.isEmpty) {
            body = EmptyState(
              icon: Icons.sticky_note_2_outlined,
              message: state is SearchNotesCubitState
                  ? AppLocalizations.of(context)!.noResults
                  : AppLocalizations.of(context)!.emptyNoteList,
            );
          } else {
            body = ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, i) => _NoteTile(note: state.notes[i]),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: KitchenowlPersistentSearchAnchor(
                  onSearch: cubit.search,
                  suggestionsBuilder: (context, controller) => state.notes
                      .map((e) => e.title)
                      .where((e) => e
                          .toLowerCase()
                          .startsWith(controller.text.toLowerCase()))
                      .toSet()
                      .toList(),
                ),
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;

  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: note.body.isNotEmpty
          ? Text(
              note.body.replaceAll(RegExp(r'[#*_>`\[\]()]'), ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: const CircleAvatar(child: Icon(Icons.sticky_note_2_outlined)),
      onTap: () => Navigator.of(context).push<UpdateEnum>(
        MaterialPageRoute(
          builder: (ctx) => NotePage(note: note),
        ),
      ),
    );
  }
}
