import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/person.dart';

class PersonAddUpdatePage extends StatefulWidget {
  final Person? person;

  const PersonAddUpdatePage({super.key, this.person});

  @override
  State<PersonAddUpdatePage> createState() => _PersonAddUpdatePageState();
}

class _PersonAddUpdatePageState extends State<PersonAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late final TextEditingController _giftIdeaController;
  DateTime? _birthday;
  bool _isLoading = false;

  bool get isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? "");
    _phoneController = TextEditingController(text: widget.person?.phone ?? "");
    _emailController = TextEditingController(text: widget.person?.email ?? "");
    _notesController = TextEditingController(text: widget.person?.notes ?? "");
    _giftIdeaController =
        TextEditingController(text: widget.person?.giftIdea ?? "");
    _birthday = widget.person?.birthday?.toLocal();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _giftIdeaController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.birthday,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() => _birthday = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final person = Person(
      id: widget.person?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      giftIdea: _giftIdeaController.text.trim().isEmpty
          ? null
          : _giftIdeaController.text.trim(),
      birthday: _birthday?.toUtc(),
      userId: widget.person?.userId,
    );

    final cubit = BlocProvider.of<PersonsCubit>(context);
    final res = isEditing
        ? await cubit.updatePerson(person)
        : await cubit.addPerson(person);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.personEdit
              : AppLocalizations.of(context)!.personAdd,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.name,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppLocalizations.of(context)!.name
                  : null,
              autofocus: !isEditing,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_rounded),
              title: Text(
                _birthday != null
                    ? MaterialLocalizations.of(context)
                        .formatMediumDate(_birthday!)
                    : AppLocalizations.of(context)!.birthday,
              ),
              trailing: _birthday != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _birthday = null),
                    )
                  : null,
              onTap: _selectBirthday,
            ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.phone,
              ),
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email,
              ),
            ),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notes,
              ),
            ),
            TextFormField(
              controller: _giftIdeaController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.giftIdeaLabel,
              ),
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
    );
  }
}
