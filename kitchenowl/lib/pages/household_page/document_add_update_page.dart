import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/document_add_update_cubit.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/helpers/named_bytearray.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/file_cache.dart';

class DocumentAddUpdatePage extends StatefulWidget {
  final Household household;
  final Document? document;

  const DocumentAddUpdatePage({
    super.key,
    required this.household,
    this.document,
  });

  @override
  State<DocumentAddUpdatePage> createState() => _DocumentAddUpdatePageState();
}

class _DocumentAddUpdatePageState extends State<DocumentAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  DateTime? _expiresAt;
  int? _ownerId;
  NamedByteArray? _file;
  String? _existingFilename;
  late final DocumentAddUpdateCubit _cubit;
  bool _isLoading = false;

  bool get isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.document?.title ?? "");
    _notesController =
        TextEditingController(text: widget.document?.notes ?? "");
    _expiresAt = widget.document?.expiresAt;
    _ownerId = widget.document?.ownerId ?? widget.document?.owner?.id;
    _existingFilename = widget.document?.filename;
    _cubit = DocumentAddUpdateCubit(widget.household);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: AppLocalizations.of(context)!.expiryDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() => _expiresAt = selected);
    }
  }

  Future<void> _pickFile() async {
    // file_picker's web implementation returns the picked bytes with the
    // PlatformFile, so the same flow works on web and desktop.
    try {
      final result = await FilePicker.pickFile(type: FileType.any);
      if (result == null || result.name.isEmpty) return;
      final bytes = await result.readAsBytes();
      if (bytes.isEmpty) throw Exception('Empty file picked.');
      if (!mounted) return;
      setState(() {
        _file = NamedByteArray(result.name, bytes);
        _existingFilename = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? filename = _existingFilename;
    if (_file != null) {
      filename = await ApiService.getInstance().uploadBytes(_file!);
      if (filename == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error),
          ),
        );
        return;
      }
      // The bytes are already on the device — keep them for offline access
      // instead of re-downloading the file we just uploaded.
      await FileCache.getInstance()
          .writeBytes(widget.household.id, filename, _file!.bytes);
    }

    final document = Document(
      id: widget.document?.id,
      title: _titleController.text.trim(),
      notes:
          _notesController.text.trim().isEmpty ? null : _notesController.text,
      expiresAt: _expiresAt,
      ownerId: _ownerId,
      filename: filename,
    );

    final cubit = BlocProvider.of<DocumentsCubit>(context);
    final res = isEditing
        ? await cubit.updateDocument(document)
        : await cubit.addDocument(document);

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
                ? AppLocalizations.of(context)!.documentEdit
                : AppLocalizations.of(context)!.documentAdd,
          ),
        ),
        body: Form(
          key: _formKey,
          child: BlocBuilder<DocumentAddUpdateCubit, DocumentAddUpdateState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.all(16),
              children: _buildFormChildren(context, state),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(
    BuildContext context,
    DocumentAddUpdateState state,
  ) {
    final loc = AppLocalizations.of(context)!;

    return [
      TextFormField(
        controller: _titleController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: loc.name,
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? loc.name : null,
        autofocus: !isEditing,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _notesController,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: loc.description,
          alignLabelWithHint: true,
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_rounded),
        title: Text(
          _expiresAt != null
              ? MaterialLocalizations.of(context).formatMediumDate(_expiresAt!)
              : loc.expiryDate,
        ),
        trailing: _expiresAt != null
            ? Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _expiresAt = null),
                ),
              )
            : null,
        onTap: _selectExpiryDate,
      ),
      DropdownButtonFormField<int?>(
        initialValue: _ownerId,
        decoration: InputDecoration(labelText: loc.person),
        items: state.members.isEmpty
            ? const <DropdownMenuItem<int?>>[]
            : [
                const DropdownMenuItem(value: null, child: Text("\u2014")),
                // Dedupe by id: duplicated entries would trip the
                // DropdownButtonFormField value-uniqueness assertion.
                ...{
                  for (final m in state.members) m.id: m,
                }.values.map(
                      (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ),
              ],
        onChanged: (value) => setState(() => _ownerId = value),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.attach_file_rounded),
        title: Text(
          _file?.filename ?? _existingFilename ?? loc.documentsFile,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: (_file != null || _existingFilename != null)
            ? Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() {
                    _file = null;
                    _existingFilename = null;
                  }),
                ),
              )
            : null,
        onTap: _pickFile,
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
            : Text(loc.save),
      ),
    ];
  }
}
