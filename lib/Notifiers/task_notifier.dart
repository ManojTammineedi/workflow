import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../db/database_helper.dart';

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]);

  Future<void> loadTasks(int workflowId) async {
    final db = DatabaseHelper.instance;
    final tasks = await db.database;
    final List<Map<String, dynamic>> taskMaps = await tasks.query(
      'tasks',
      where: 'workflow_id = ?',
      whereArgs: [workflowId],
      orderBy: 'task_order ASC', // Order by task_order column
    );

    state = taskMaps.map((taskMap) => Task.fromMap(taskMap)).toList();
  }

  Future<void> addTask(Task task) async {
    final db = DatabaseHelper.instance;
    final taskId =
        await db.database.then((db) => db.insert('tasks', task.toMap()));
    state = [...state, task.copyWith(id: taskId)];
  }

  Future<void> deleteTask(int id) async {
    final db = DatabaseHelper.instance;
    await db.database
        .then((db) => db.delete('tasks', where: 'id = ?', whereArgs: [id]));
    state = state.where((task) => task.id != id).toList();
  }

  Future<void> updateTask(Task updatedTask) async {
    final db = DatabaseHelper.instance;
    await db.database.then((db) => db.update(
          'tasks',
          updatedTask.toMap(),
          where: 'id = ?',
          whereArgs: [updatedTask.id],
        ));
    state = state
        .map((task) => task.id == updatedTask.id ? updatedTask : task)
        .toList();
  }

  void reorderTasks(int oldIndex, int newIndex, int workflowId) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final task = state.removeAt(oldIndex);
    state.insert(newIndex, task);

    // Update the task order in memory and database
    await _updateTaskOrder();
    await loadTasks(workflowId);
  }

  Future<void> _updateTaskOrder() async {
    final db = DatabaseHelper.instance;

    for (int i = 0; i < state.length; i++) {
      state[i] = state[i].copyWith(taskOrder: i + 1);

      // Update the task order in the database
      await db.database.then((db) => db.update(
            'tasks',
            {'task_order': state[i].taskOrder},
            where: 'id = ?',
            whereArgs: [state[i].id],
          ));
    }
  }
}

final taskProvider =
    StateNotifierProvider.family<TaskNotifier, List<Task>, int>(
  (ref, workflowId) => TaskNotifier()..loadTasks(workflowId),
);
