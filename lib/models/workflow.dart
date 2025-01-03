import 'package:workflow/models/task.dart';

class Workflow {
  final int? id;
  final String name;
  final String creationDate;
  final String status;
// You should include a tasks field to manage tasks

  Workflow({
    this.id,
    required this.name,
    required this.creationDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creation_date': creationDate,
      'status': status,
    };
  }
}

  // Implementing the copyWith method

