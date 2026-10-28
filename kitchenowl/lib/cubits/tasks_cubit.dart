import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/task.dart';

class TasksCubit extends Cubit<TasksCubitState> {
  final Household household;
  final TransactionHandler _transactionHandler;
  Future<void>? _refreshThread;

  TasksCubit(this.household)
      : _transactionHandler = TransactionHandler.getInstance(),
        super(const LoadingTasksCubitState()) {
    refresh();
    ApiService.getInstance().onTaskUpdate(onTaskUpdate);
  }

  TasksCubit.forTesting(
    TransactionHandler transactionHandler,
    this.household,
  )   : _transactionHandler = transactionHandler,
        super(const LoadingTasksCubitState()) {
    refresh();
  }

  void onTaskUpdate(dynamic data) {
    refresh();
  }

  Future<bool> addTask(Task task) async {
    final res = await _transactionHandler.runTransaction(
      TransactionTaskAdd(household: household, task: task),
    );
    await refresh();

    return res;
  }

  Future<bool> updateTask(Task task) async {
    final res = await _transactionHandler.runTransaction(
      TransactionTaskUpdate(task: task),
    );
    await refresh();

    return res;
  }

  /// Marks [task] done (or reopens it). The backend stamps completed_at
  /// and, for recurring tasks, materializes the next occurrence — which
  /// arrives via the task:update socket and triggers a refresh.
  Future<void> setDone(Task task, {required bool done}) {
    return updateTask(task.copyWith(status: done ? 'done' : 'open'));
  }

  Future<bool> deleteTask(Task task) async {
    final res = await _transactionHandler.runTransaction(
      TransactionTaskRemove(task: task),
    );
    await refresh();

    return res;
  }

  Future<void> refresh() {
    if (_refreshThread == null) {
      _refreshThread = _refresh();
    }

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    final tasks = await _transactionHandler.runTransaction(
      TransactionTasksGet(household: household),
    );
    if (_refreshThread != null) {
      emit(ListTasksCubitState(tasks: tasks));
      _refreshThread = null;
    }
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offTaskUpdate(onTaskUpdate);
    super.close();
  }
}

abstract class TasksCubitState extends Equatable {
  const TasksCubitState();

  List<Task> get tasks;

  @override
  List<Object?> get props => [];
}

class LoadingTasksCubitState extends TasksCubitState {
  const LoadingTasksCubitState();

  @override
  List<Task> get tasks => const [];
}

class ListTasksCubitState extends TasksCubitState {
  final List<Task> tasks;

  const ListTasksCubitState({this.tasks = const []});

  @override
  List<Object?> get props => <Object?>[...tasks];
}
