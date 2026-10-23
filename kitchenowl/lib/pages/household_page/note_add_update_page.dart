import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/note_add_update_cubit.dart';
import 'package:kitchenowl/cubits/notes_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/note.dart';
import 'package:kitchenowl/models/tag.dart';

class NoteAddUpdatePage extends StatefulWidget {
  final Household household;
  final Note? note;

  const NoteAddUpdatePage({
    super.key,
    required this.household,
    this.note,
  });

  @override
  State<NoteAddUpdatePage> createState() => _NoteAddUpdatePageState();
}

class _NoteAddUpdatePageState extends State<NoteAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final NoteAddUpdateCubit _cubit;
  bool _isLoading = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? "");
    _bodyController = TextEditingController(text: widget.note?.body ?? "");
    _cubit = NoteAddUpdateCubit(
      widget.household,
      selectedTags: Set<Tag>.from(widget.note?.tags ?? const <Tag>[]),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final note = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      body: _bodyController.text,
      tags: _cubit.state.selectedTags.toList(),
    );

    final cubit = BlocProvider.of<NotesCubit>(context);
    final res =
        isEditing ? await cubit.updateNote(note) : await cubit.addNote(note);

    if (!mounted) return;
    if (res) {
      Navigator.of(context).pop(UpdateEnum.updated);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing
                ? AppLocalizations.of(context)!.noteEdit
                : AppLocalizations.of(context)!.noteAdd,
          ),
        ),
        body: Form(
          key: _formKey,
          child: BlocBuilder<NoteAddUpdateCubit, NoteAddUpdateState>(
            builder: (context, tagState) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.name,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppLocalizations.of(context)!.name
                      : null,
                  autofocus: !isEditing,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 10,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.tags),
                const SizedBox(height: 8),
                KitchenOwlTagSelector(
                  tags: tagState.tags,
                  selectedTags: tagState.selectedTags,
                  onSelect: _cubit.selectTag,
                  onAdd: _cubit.addTag,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
