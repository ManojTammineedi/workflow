import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workflow/models/workflow.dart';
import 'package:workflow/db/database_helper.dart';

class WorkflowNotifier extends StateNotifier<List<Workflow>> {
  WorkflowNotifier() : super([]);

  Future<void> loadWorkflows({String? status}) async {
    final db = DatabaseHelper.instance;
    final workflows = await db.database;
    List<Map<String, dynamic>> workflowMaps;

    if (status == null || status == 'All') {
      workflowMaps = await workflows.query('workflows');
    } else {
      workflowMaps = await workflows.query(
        'workflows',
        where: 'status = ?',
        whereArgs: [status],
      );
    }

    print('Loaded workflows: $workflowMaps');
    state = workflowMaps.map((workflowMap) {
      return Workflow(
        id: workflowMap['id'],
        name: workflowMap['name'],
        creationDate: workflowMap['creation_date'],
        status: workflowMap['status'],
      );
    }).toList();
  }

  Future<void> addWorkflow(
      String name, String creationDate, String status) async {
    final db = DatabaseHelper.instance;
    final newWorkflowId =
        await db.database.then((db) => db.insert('workflows', {
              'name': name,
              'creation_date': creationDate,
              'status': status,
            }));

    final newWorkflow = Workflow(
      id: newWorkflowId,
      name: name,
      creationDate: creationDate,
      status: status,
    );

    state = [...state, newWorkflow];
  }

  Future<void> deleteWorkflow(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteWorkflow(id);
    state = state.where((workflow) => workflow.id != id).toList();
  }

  Future<void> updateWorkflow(int id, String name, String status) async {
    final db = DatabaseHelper.instance;
    await db.updateWorkflow(id, name, status);
    state = state.map((workflow) {
      if (workflow.id == id) {
        return Workflow(
          id: id,
          name: name,
          creationDate: workflow.creationDate,
          status: status,
        );
      }
      return workflow;
    }).toList();
  }
}

final workflowsProvider =
    StateNotifierProvider<WorkflowNotifier, List<Workflow>>((ref) {
  return WorkflowNotifier();
});
