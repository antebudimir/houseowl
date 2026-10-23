import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/task.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

/// Tasks are online-only: there is no offline cache, mirroring planned
/// buy transactions.
class TransactionTasksGet extends Transaction<List<Task>> {
  final Household household;

  TransactionTasksGet({
    required this.household,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionTasksGet",
        );

  @override
  Future<List<Task>> runLocal() async => [];

  @override
  Future<List<Task>> runOnline() async =>
      await ApiService.getInstance().getTasks(household) ?? [];
}

class TransactionTaskAdd extends Transaction<bool> {
  final Household household;
  final Task task;

  TransactionTaskAdd({
    required this.household,
    required this.task,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionTaskAdd",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addTask(household, task) != null;
}

class TransactionTaskUpdate extends Transaction<bool> {
  final Task task;

  TransactionTaskUpdate({
    required this.task,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionTaskUpdate",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().updateTask(task);
}

class TransactionTaskRemove extends Transaction<bool> {
  final Task task;

  TransactionTaskRemove({
    required this.task,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionTaskRemove",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().deleteTask(task);
}
