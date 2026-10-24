import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/task_add_update_cubit.dart';
import 'package:houseowl/cubits/tasks_cubit.dart';
import 'package:houseowl/enums/task_recurrence_enum.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/models/planned_buy.dart';
import 'package:houseowl/models/tag.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/services/api/api_service.dart';

class TaskAddUpdatePage extends StatefulWidget {
  final Household household;
  final Task? task;

  const TaskAddUpdatePage({
    super.key,
    required this.household,
    this.task,
  });

  @override
  State<TaskAddUpdatePage> createState() => _TaskAddUpdatePageState();
}

class _TaskAddUpdatePageState extends State<TaskAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late TaskRecurrence _recurrence;
  late int _priority;
  DateTime? _dueDate;
  int? _assigneeId;
  int? _buyId;
  late final Future<List<Person>> _persons;
  late final Future<List<PlannedBuy>> _buys;
  late final TaskAddUpdateCubit _cubit;
  bool _isLoading = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? "");
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? "");
    _cubit = TaskAddUpdateCubit(
      widget.household,
      selectedTags: Set<Tag>.from(widget.task?.tags ?? const <Tag>[]),
    );
    _recurrence = widget.task?.recurrence ?? TaskRecurrence.none;
    _priority = widget.task?.priority ?? 0;
    _dueDate = widget.task?.dueDate;
    _assigneeId = widget.task?.assigneeId;
    _buyId = widget.task?.buyId;
    _persons = ApiService.getInstance()
        .getPersons(widget.household)
        .then((v) => v ?? const <Person>[]);
    _buys = ApiService.getInstance()
        .getPlannedBuys(widget.household)
        .then((v) => v ?? const <PlannedBuy>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: AppLocalizations.of(context)!.dueDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final task = Task(
      id: widget.task?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: widget.task?.status ?? 'open',
      priority: _priority,
      recurrence: _recurrence,
      dueDate: _dueDate,
      assigneeId: _assigneeId,
      buyId: _buyId,
      tags: _cubit.state.selectedTags.toList(),
    );

    final cubit = BlocProvider.of<TasksCubit>(context);
    final res =
        isEditing ? await cubit.updateTask(task) : await cubit.addTask(task);

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
                ? AppLocalizations.of(context)!.taskEdit
                : AppLocalizations.of(context)!.taskAdd,
          ),
        ),
        body: Form(
          key: _formKey,
          child: BlocBuilder<TaskAddUpdateCubit, TaskAddUpdateState>(
            builder: (context, tagState) => ListView(
              padding: const EdgeInsets.all(16),
              children: _buildFormChildren(context, tagState),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(
    BuildContext context,
    TaskAddUpdateState tagState,
  ) {
    final loc = AppLocalizations.of(context)!;
    final priorities = [
      loc.priorityLow,
      loc.priorityNormal,
      loc.priorityHigh,
      loc.priorityUrgent,
    ];

    return [
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: loc.name),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? loc.name : null,
        autofocus: !isEditing,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: loc.description,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        initialValue: _priority,
        decoration: InputDecoration(labelText: loc.priority),
        items: [
          for (var i = 0; i < priorities.length; i++)
            DropdownMenuItem(value: i, child: Text(priorities[i])),
        ],
        onChanged: (value) => setState(() => _priority = value ?? _priority),
      ),
      DropdownButtonFormField<TaskRecurrence>(
        initialValue: _recurrence,
        decoration: InputDecoration(labelText: loc.taskRecurrence),
        items: [
          for (final recurrence in TaskRecurrence.values)
            DropdownMenuItem(
              value: recurrence,
              child: Text(recurrence.toLocalizedString(context)),
            ),
        ],
        onChanged: (value) =>
            setState(() => _recurrence = value ?? _recurrence),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_rounded),
        title: Text(
          _dueDate != null
              ? MaterialLocalizations.of(context).formatMediumDate(_dueDate!)
              : loc.dueDate,
        ),
        trailing: _dueDate != null
            ? Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _dueDate = null),
                ),
              )
            : null,
        onTap: _selectDueDate,
      ),
      FutureBuilder<List<Person>>(
        future: _persons,
        builder: (context, snapshot) {
          final persons = snapshot.data ?? const <Person>[];

          return DropdownButtonFormField<int?>(
            initialValue: _assigneeId,
            decoration: InputDecoration(labelText: loc.assignee),
            items: persons.isEmpty
                ? const <DropdownMenuItem<int?>>[]
                : [
                    const DropdownMenuItem(value: null, child: Text("\u2014")),
                    // Dedupe by id: duplicated entries would trip the
                    // DropdownButtonFormField value-uniqueness assertion.
                    ...{
                      for (final p in persons) p.id: p,
                    }.values.map(
                          (p) => DropdownMenuItem(
                              value: p.id, child: Text(p.name)),
                        ),
                  ],
            onChanged: (value) => setState(() => _assigneeId = value),
          );
        },
      ),
      FutureBuilder<List<PlannedBuy>>(
        future: _buys,
        builder: (context, snapshot) {
          final buys = snapshot.data?.where((b) => !b.isAcquired).toList() ??
              const <PlannedBuy>[];

          return DropdownButtonFormField<int?>(
            initialValue: _buyId,
            decoration: InputDecoration(labelText: loc.buyLink),
            items: buys.isEmpty
                ? const <DropdownMenuItem<int?>>[]
                : [
                    const DropdownMenuItem(value: null, child: Text("\u2014")),
                    // Dedupe by id: duplicated entries would trip the
                    // DropdownButtonFormField value-uniqueness assertion.
                    ...{
                      for (final b in buys) b.id: b,
                    }.values.map(
                          (b) => DropdownMenuItem(
                              value: b.id, child: Text(b.name)),
                        ),
                  ],
            onChanged: (value) => setState(() => _buyId = value),
          );
        },
      ),
      const SizedBox(height: 16),
      Text(loc.tags),
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
            : Text(loc.save),
      ),
    ];
  }
}
