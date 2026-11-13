import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/household_cubit.dart';
import 'package:houseowl/cubits/tasks_cubit.dart';
import 'package:houseowl/enums/task_recurrence_enum.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/pages/household_page/task_add_update_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

enum TaskSortMode { dueDate, priority, name }

class _TasksPageState extends State<TasksPage> {
  TaskSortMode _sort = TaskSortMode.dueDate;
  int? _assigneeId;
  String? _tag;

  int _dueCompare(Task a, Task b) {
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd == null) return (a.id ?? 0).compareTo(b.id ?? 0);
    if (ad == null) return 1; // undated tasks last
    if (bd == null) return -1;
    final byDate = ad.compareTo(bd);
    return byDate != 0 ? byDate : (a.id ?? 0).compareTo(b.id ?? 0);
  }

  int _compare(Task a, Task b) {
    switch (_sort) {
      case TaskSortMode.priority:
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : _dueCompare(a, b);
      case TaskSortMode.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case TaskSortMode.dueDate:
        return _dueCompare(a, b);
    }
  }

  List<Task> _applyFilters(List<Task> tasks) {
    return tasks
        .where((t) {
          if (_assigneeId != null && t.assigneeId != _assigneeId) return false;
          if (_tag != null && !t.tags.any((tag) => tag.name == _tag)) {
            return false;
          }
          return true;
        })
        .toList()
      ..sort(_compare);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<TasksCubit>(context);

    return SafeArea(
      child: BlocBuilder<TasksCubit, TasksCubitState>(
        builder: (context, state) {
          final filtered = _applyFilters(state.tasks);
          final open = filtered.where((t) => !t.isDone).toList();
          final done = filtered.where((t) => t.isDone).toList();

          final Widget body;
          if (state is LoadingTasksCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.tasks.isEmpty) {
            body = EmptyState(
              icon: Icons.checklist_rounded,
              message: AppLocalizations.of(context)!.noTasks,
            );
          } else if (filtered.isEmpty) {
            body = EmptyState(
              icon: Icons.filter_alt_off_rounded,
              message: AppLocalizations.of(context)!.noResults,
            );
          } else {
            body = ListView(
              children: [
                if (open.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.checklist_rounded,
                      message: AppLocalizations.of(context)!.noTasks,
                    ),
                  )
                else
                  for (final task in open)
                    _TaskTile(
                      task: task,
                      onEdit: () => _edit(context, cubit, task),
                      onDelete: () => _confirmDelete(context, cubit, task),
                      onToggle: () => cubit.setDone(task, done: !task.isDone),
                    ),
                if (done.isNotEmpty)
                  ExpansionTile(
                    title: Text(
                      AppLocalizations.of(context)!.tasksCompleted(done.length),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    initiallyExpanded: open.isEmpty,
                    children: [
                      for (final task in done)
                        _TaskTile(
                          task: task,
                          onEdit: () => _edit(context, cubit, task),
                          onDelete: () => _confirmDelete(context, cubit, task),
                          onToggle: () =>
                              cubit.setDone(task, done: !task.isDone),
                        ),
                    ],
                  ),
              ],
            );
          }

          return Column(
            children: [
              if (state is! LoadingTasksCubitState && state.tasks.isNotEmpty)
                _filterBar(context, state.tasks),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: body,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar(BuildContext context, List<Task> tasks) {
    final loc = AppLocalizations.of(context)!;
    final assignees = <int, Member>{};
    for (final task in tasks) {
      final assignee = task.assignee;
      final id = assignee?.id;
      if (id != null) assignees[id] = assignee!;
    }
    final tagNames = <String>{
      for (final task in tasks)
        for (final tag in task.tags) tag.name,
    }.toList()
      ..sort();
    final hasFilters =
        _assigneeId != null || _tag != null || _sort != TaskSortMode.dueDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<TaskSortMode>(
                  value: _sort,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: TaskSortMode.dueDate,
                      child: Text(loc.dueDate),
                    ),
                    DropdownMenuItem(
                      value: TaskSortMode.priority,
                      child: Text(loc.priority),
                    ),
                    DropdownMenuItem(
                      value: TaskSortMode.name,
                      child: Text(loc.name),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
                if (assignees.isNotEmpty)
                  DropdownButton<int?>(
                    value: _assigneeId,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(loc.all),
                      ),
                      for (final assignee in assignees.values)
                        DropdownMenuItem<int?>(
                          value: assignee.id,
                          child: Text(assignee.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _assigneeId = value),
                  ),
                if (tagNames.isNotEmpty)
                  DropdownButton<String?>(
                    value: _tag,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(loc.all),
                      ),
                      for (final name in tagNames)
                        DropdownMenuItem<String?>(
                          value: name,
                          child: Text(name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _tag = value),
                  ),
              ],
            ),
          ),
          if (hasFilters)
            IconButton(
              tooltip: loc.clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              onPressed: () => setState(() {
                _sort = TaskSortMode.dueDate;
                _assigneeId = null;
                _tag = null;
              }),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    TasksCubit cubit,
    Task task,
  ) async {
    final res = await Navigator.of(context).push<UpdateEnum>(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: cubit,
          child: TaskAddUpdatePage(
            household: BlocProvider.of<HouseholdCubit>(context).state.household,
            task: task,
          ),
        ),
      ),
    );
    if (res == UpdateEnum.updated) cubit.refresh();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TasksCubit cubit,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(ctx)!.taskDeleteConfirmation(task.name),
        ),
        content: Text(task.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.deleteTask(task);
    }
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitles = <String>[
      if (task.dueDate != null)
        MaterialLocalizations.of(context).formatMediumDate(task.dueDate!),
      if (task.reminderMinutes != null && task.dueDate != null)
        ReminderPicker.labelFor(context, task.reminderMinutes),
      if (task.recurrence != TaskRecurrence.none)
        task.recurrence.toLocalizedString(context),
      if (task.assignee != null) task.assignee!.name,
      if (task.tags.isNotEmpty) task.tags.map((t) => t.name).join(", "),
    ];

    return ListTile(
      leading: IconButton(
        tooltip: task.isDone
            ? AppLocalizations.of(context)!.taskReopen
            : AppLocalizations.of(context)!.taskDone,
        onPressed: onToggle,
        icon: Icon(
          task.isDone
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 22,
          color: task.isDone ? Theme.of(context).disabledColor : null,
        ),
      ),
      title: Text(
        task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: task.isDone
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Theme.of(context).disabledColor,
              )
            : null,
      ),
      subtitle: subtitles.isEmpty
          ? null
          : Text(
              subtitles.join(" · "),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.assignee != null) ...[
            CircleAvatar(
              radius: 10,
              child: Text(
                task.assignee!.name.isNotEmpty
                    ? task.assignee!.name[0].toUpperCase()
                    : "?",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (task.priority > 0)
            Icon(
              Icons.flag_rounded,
              size: 20,
              color: switch (task.priority) {
                3 => Theme.of(context).colorScheme.error,
                2 => Theme.of(context).colorScheme.tertiary,
                _ => Theme.of(context).colorScheme.primary,
              },
            ),
        ],
      ),
      onTap: onEdit,
      onLongPress: onDelete,
    );
  }
}
