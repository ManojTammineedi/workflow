class Task {
  final int? id;
  final int workflowId;
  final String title;
  final String? description;
  final String type;
  final String? parameters;
  final int taskOrder;

  Task({
    this.id,
    required this.workflowId,
    required this.title,
    this.description,
    required this.type,
    this.parameters,
    required this.taskOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflow_id': workflowId,
      'title': title,
      'description': description,
      'type': type,
      'parameters': parameters,
      'task_order': taskOrder,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      workflowId: map['workflow_id'],
      title: map['title'],
      description: map['description'],
      type: map['type'],
      parameters: map['parameters'],
      taskOrder: map['task_order'],
    );
  }

  Task copyWith({
    int? id,
    int? workflowId,
    String? title,
    String? description,
    String? type,
    String? parameters,
    int? taskOrder,
  }) {
    return Task(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      taskOrder: taskOrder ?? this.taskOrder,
    );
  }
}
