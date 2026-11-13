import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/tasks_cubit.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/pages/household_page/tasks_page.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/task.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Serves a fixed task list for [TransactionTasksGet] and defers everything
/// else to the local (no-op) implementation.
class _SeededTasksHandler extends TransactionHandler {
  final List<Task> tasks;

  _SeededTasksHandler(this.tasks) : super.internal();

  @override
  Future<T> runTransaction<T>(
    Transaction<T> t, {
    bool forceOffline = false,
    bool saveTransaction = true,
  }) {
    if (t is TransactionTasksGet) return Future.value(tasks as T);
    return t.runLocal();
  }
}

Future<void> _pumpPage(WidgetTester tester, {required List<Task> tasks}) async {
  final household = Household(id: 1, name: "Test");
  final cubit = TasksCubit.forTesting(_SeededTasksHandler(tasks), household);
  await tester.pumpWidget(
    BlocProvider<TasksCubit>.value(
      value: cubit,
      child: mui.MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const mui.Scaffold(body: TasksPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await cubit.close();
}

void main() {
  testWidgets("open tasks are sorted by due date by default", (tester) async {
    final soon = DateTime.now().add(const Duration(days: 1));
    final later = DateTime.now().add(const Duration(days: 5));
    await _pumpPage(tester, tasks: [
      Task(id: 2, name: "Later", dueDate: later),
      Task(id: 1, name: "Sooner", dueDate: soon),
    ]);

    expect(find.text("Sooner"), findsOneWidget);
    expect(find.text("Later"), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("Sooner")).dy,
      lessThan(tester.getTopLeft(find.text("Later")).dy),
    );
  });

  testWidgets("switching the sort to priority reorders the list",
      (tester) async {
    await _pumpPage(tester, tasks: [
      Task(id: 1, name: "Low", priority: 0),
      Task(id: 2, name: "High", priority: 3),
    ]);

    // Default due-date sort leaves equal/undated tasks in id order: Low, High.
    expect(
      tester.getTopLeft(find.text("Low")).dy,
      lessThan(tester.getTopLeft(find.text("High")).dy),
    );

    // Open the sort dropdown (shows the current "Due date") and pick Priority.
    await tester.tap(find.text("Due date"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Priority").last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text("High")).dy,
      lessThan(tester.getTopLeft(find.text("Low")).dy),
    );
  });
}
