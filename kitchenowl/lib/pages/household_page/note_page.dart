import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/notes_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/note.dart';

import 'note_add_update_page.dart';

class NotePage extends StatelessWidget {
  final Note note;

  const NotePage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final res = await Navigator.of(context).push<UpdateEnum>(
                MaterialPageRoute(
                  builder: (ctx) => NoteAddUpdatePage(
                    household: BlocProvider.of<NotesCubit>(context).household,
                    note: note,
                  ),
                ),
              );
              if (res == UpdateEnum.updated && context.mounted) {
                Navigator.of(context).pop(UpdateEnum.updated);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (note.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                runSpacing: 8,
                spacing: 5,
                children: note.tags
                    .map(
                      (e) => Chip(
                        label: Text(e.name),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
          KitchenOwlMarkdownBody(data: note.body),
        ],
      ),
    );
  }
}
