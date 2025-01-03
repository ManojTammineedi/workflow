import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workflow/Notifiers/workflow_notifier.dart';
import 'package:workflow/models/workflow.dart';
import 'package:workflow/components/my_textfield.dart';
import 'package:workflow/pages/tasks_page.dart';

class HomePage extends ConsumerWidget {
  final selectedStatusProvider = StateProvider<String>((ref) => 'All');
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(selectedStatusProvider);
    final workflows = ref.watch(workflowsProvider);
    if (workflows.isEmpty) {
      ref.read(workflowsProvider.notifier).loadWorkflows();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: Text('Workflows'),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,

        actions: [
          CircleAvatar(
            backgroundColor: Colors.black,
            child: Text(
              'T', // Display the first letter of the email
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(workflowsProvider.notifier).loadWorkflows();
        },
        child: workflows.isEmpty
            ? Center(child: Text('No workflows available.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workflows',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          value: selectedStatus,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(selectedStatusProvider.notifier).state =
                                  value;
                              ref
                                  .read(workflowsProvider.notifier)
                                  .loadWorkflows(status: value);
                            }
                          },
                          items: [
                            'All',
                            'Draft',
                            'In Progress',
                            'Completed',
                            'On Hold'
                          ].map<DropdownMenuItem<String>>((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: workflows.any((workflow) =>
                              selectedStatus == 'All' ||
                              workflow.status == selectedStatus)
                          ? ListView.builder(
                              itemCount: workflows.length,
                              itemBuilder: (context, index) {
                                final workflow = workflows[index];

                                // Print all workflow data to the console for debugging
                                print('Workflow ID: ${workflow.id}');
                                print('Workflow Name: ${workflow.name}');
                                print('Workflow Status: ${workflow.status}');
                                print(
                                    'Creation Date: ${workflow.creationDate}');
                                print('-----------------------------------');

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    style: ListTileStyle.list,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkflowTasksPage(
                                            workflowId: workflow.id!,
                                            workflowName: workflow.name,
                                          ),
                                        ),
                                      );
                                    },
                                    title: Text(
                                      workflow.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent, // Title color
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Status: ${workflow.status}',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            workflow.status), // Subtitle color
                                      ),
                                    ),
                                    tileColor: Colors
                                        .white, // Background color of the tile
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            16), // Padding inside the tile
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8), // Rounded corners
                                      side: BorderSide(
                                        color:
                                            Colors.blueAccent, // Border color
                                        width: 1, // Border width
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color:
                                                Colors.blue, // Edit icon color
                                          ),
                                          onPressed: () {
                                            _showEditDialog(
                                                context, ref, workflow);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color:
                                                Colors.red, // Delete icon color
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                    workflowsProvider.notifier)
                                                .deleteWorkflow(workflow.id!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                'No workflows with status: $selectedStatus',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateWorkflowDialog(context, ref);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateWorkflowDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String status = 'Draft'; // Default status set to Draft
    final creationDate = DateTime.now().toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Create Workflow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextField(
              controller: nameController,
              hintText: 'Workflow Name',
              obscureText: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final workflowName = nameController.text.trim();

              if (workflowName.isNotEmpty) {
                ref.read(workflowsProvider.notifier).addWorkflow(
                      workflowName,
                      creationDate,
                      status,
                    );
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Workflow workflow) {
    final nameController = TextEditingController(text: workflow.name);

    // Define the available statuses
    List<String> statusOptions = [
      'Draft',
      'In Progress',
      'Completed',
      'On Hold'
    ];

    // Initial status is set to the workflow's current status
    String status = workflow.status;

    // Stateful widget to manage the selected status in the dropdown
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Edit Workflow'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // TextField for workflow name
                  MyTextField(
                    controller: nameController,
                    hintText: 'Workflow Name',
                    obscureText: false,
                  ),

                  // DropdownButton for selecting status
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey), // Border on all sides
                      borderRadius:
                          BorderRadius.circular(5), // Optional: Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 8), // Padding inside the container
                    child: DropdownButton<String>(
                      dropdownColor: Colors.white, // Dropdown background color
                      value: status, // Default selected value
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            status = newValue; // Update the selected status
                          });
                        }
                      },
                      items: statusOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      isExpanded: true, // Makes the dropdown take full width
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(workflowsProvider.notifier).updateWorkflow(
                          workflow.id!,
                          nameController.text,
                          status, // Pass the updated status
                        );
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange; // Color for In Progress status
      case 'Completed':
        return Colors.green; // Color for Completed status
      case 'On Hold':
        return Colors.redAccent; // Color for On Hold status
      case 'Draft':
      default:
        return Colors.grey; // Color for Draft status or default
    }
  }
}
