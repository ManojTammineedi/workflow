import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workflow/Notifiers/task_notifier.dart';
import 'package:workflow/components/my_textfield.dart';
import '../models/task.dart';

class WorkflowTasksPage extends ConsumerWidget {
  final int workflowId;
  final String workflowName;

  WorkflowTasksPage({required this.workflowId, required this.workflowName});

  void _showTaskForm(BuildContext context, WidgetRef ref,
      {Task? existingTask}) {
    final isEditing = existingTask != null;
    final titleController =
        TextEditingController(text: isEditing ? existingTask!.title : '');
    final descriptionController =
        TextEditingController(text: isEditing ? existingTask.description : '');
    final type =
        ValueNotifier<String>(isEditing ? existingTask.type : 'Computation');
    final parametersController =
        TextEditingController(text: isEditing ? existingTask.parameters : '');
    final ScrollController _scrollController = ScrollController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isEditing ? 'Edit Task' : 'Create Task'),
        content: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              MyTextField(
                controller: titleController,
                hintText: 'Task Title',
                obscureText: false,
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                height: 200, // Fixed height for the container
                padding: EdgeInsets.all(5),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Task Description....',
                        border: InputBorder.none,
                      ),
                      maxLines: null, // Allow multiline input
                      expands: true, // Make the TextField fill available space
                    ),
                  ),
                ),
              ),
              // MyTextField(
              //   controller: descriptionController,
              //   hintText: 'Task Description',
              //   obscureText: false,
              // ),
              SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Border on all sides
                  borderRadius:
                      BorderRadius.circular(5), // Optional: Rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ValueListenableBuilder<String>(
                    valueListenable: type,
                    builder: (_, currentType, __) =>
                        DropdownButtonFormField<String>(
                      value: currentType,
                      items: ['Computation', 'Delay', 'Decision']
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) type.value = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Task Type',
                        border: InputBorder.none, // Remove underline
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10), // Adjust padding
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Dynamic input fields based on task type
              ValueListenableBuilder<String>(
                valueListenable: type,
                builder: (_, currentType, __) {
                  if (currentType == 'Computation') {
                    return MyTextField(
                      controller: parametersController,
                      hintText: 'Math Operation (e.g., 2 + 3)',
                      obscureText: false,
                    );
                  } else if (currentType == 'Delay') {
                    return TextField(
                      controller: parametersController,
                      decoration: InputDecoration(
                        labelText: 'Delay in Seconds',
                      ),
                      keyboardType: TextInputType.number,
                    );
                  } else if (currentType == 'Decision') {
                    return MyTextField(
                      controller: parametersController,
                      hintText: 'Branching Condition (e.g., X > 5)',
                      obscureText: false,
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final task = Task(
                id: existingTask?.id,
                workflowId: workflowId,
                title: titleController.text,
                description: descriptionController.text,
                type: type.value,
                parameters: parametersController.text,
                taskOrder: existingTask?.taskOrder ??
                    ref.read(taskProvider(workflowId)).length + 1,
              );

              if (isEditing) {
                ref.read(taskProvider(workflowId).notifier).updateTask(task);
              } else {
                ref.read(taskProvider(workflowId).notifier).addTask(task);
              }

              Navigator.of(ctx).pop();
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider(workflowId));
    if (tasks.isEmpty) {
      ref.read(taskProvider(workflowId).notifier).loadTasks(workflowId);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('$workflowName Workflow Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(taskProvider(workflowId).notifier)
              .loadTasks(workflowId);
        },
        child: tasks.isEmpty
            ? Center(child: Text('No tasks available.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) async {
                    ref
                        .read(taskProvider(workflowId).notifier)
                        .reorderTasks(oldIndex, newIndex, workflowId);
                  },
                  children: List.generate(
                    tasks.length,
                    (index) {
                      final task = tasks[index];
                      return Padding(
                        key: ValueKey(task.id),
                        padding: const EdgeInsets.only(
                            bottom: 8.0), // Add space below each tile
                        child: ListTile(
                          style: ListTileStyle.list,
                          leading: CircleAvatar(
                            child: Text(
                              (index + 1).toString(),
                              style: TextStyle(
                                color: Colors.white, // Text color
                              ),
                            ),
                            backgroundColor: Colors.blueAccent, // Circle color
                          ),
                          title: Text(
                            task.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent, // Title color
                            ),
                          ),
                          subtitle: Text(
                            'Type: ${task.type}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          tileColor:
                              Colors.white, // Background color of the tile
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, // Padding inside the tile
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                            side: BorderSide(
                              color: Colors.blueAccent, // Border color
                              width: 1, // Border width
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.blue, // Edit icon color
                                ),
                                onPressed: () => _showTaskForm(context, ref,
                                    existingTask: task),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red, // Delete icon color
                                ),
                                onPressed: () {
                                  ref
                                      .read(taskProvider(workflowId).notifier)
                                      .deleteTask(task.id!);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(context, ref),
        child: Icon(Icons.add),
      ),
    );
  }
}
