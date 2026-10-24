import 'dart:convert';

import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/task.dart';
import 'package:houseowl/services/api/api_service.dart';

extension TaskApi on ApiService {
  String taskRoute({Household? household, Task? task}) =>
      "${household != null ? householdPath(household) : ""}/task${task?.id != null ? "/${task!.id}" : ""}";

  Future<List<Task>?> getTasks(Household household, {String status = 'all'}) async {
    final res = await get("${taskRoute(household: household)}?status=$status");
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => Task.fromJson(e))
        .toList();
  }

  Future<Task?> addTask(Household household, Task task) async {
    final res = await post(
      taskRoute(household: household),
      jsonEncode(task.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Task.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateTask(Task task) async {
    final res = await post(
      taskRoute(task: task),
      jsonEncode(task.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteTask(Task task) async {
    final res = await delete(taskRoute(task: task));

    return res.statusCode == 200;
  }

  void onTaskUpdate(dynamic Function(dynamic) handler) {
    socket.on("task:update", handler);
  }

  void offTaskUpdate(dynamic Function(dynamic) handler) {
    socket.off("task:update", handler);
  }
}
