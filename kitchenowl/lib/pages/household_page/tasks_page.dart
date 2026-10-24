import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/tasks_cubit.dart';
import 'package:kitchenowl/enums/task_recurrence_enum.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/task.dart';
import 'package:kitchenowl/pages/household_page/task_add_update_page.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<TasksCubit>(context);

    return SafeArea(
      child: BlocBuilder<TasksCubit, TasksCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingTasksCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.tasks.isEmpty) {
            body = Center(
              child: Text(AppLocalizations.of(context)!.noTasks),
            );
          } else {
            final open = state.tasks.where((t) => !t.isDone).toList();
            final done = state.tasks.where((t) => t.isDone).toList();

            body = ListView(
              children: [
                if (open.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTasks,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  for (final task in open)
                    _TaskTile(
                      task: task,
                      onEdit: () => _edit(context, cubit, task),
                      onDelete: () => _confirmDelete(context, cubit, task),
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
                        ),
                    ],
                  ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: body,
          );
        },
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

  const _TaskTile({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitles = <String>[
      if (task.dueDate != null)
        MaterialLocalizations.of(context).formatMediumDate(task.dueDate!),
      if (task.recurrence != TaskRecurrence.none)
        task.recurrence.toLocalizedString(context),
      if (task.assignee != null) task.assignee!.name,
      if (task.tags.isNotEmpty) task.tags.map((t) => t.name).join(", "),
    ];

    return ListTile(
      leading: Icon(
        task.isDone
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 22,
        color: task.isDone ? Theme.of(context).disabledColor : null,
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
      trailing: task.priority > 0
          ? const Icon(Icons.flag_rounded, size: 20)
          : null,
      onTap: onEdit,
      onLongPress: onDelete,
    );
  }
}
