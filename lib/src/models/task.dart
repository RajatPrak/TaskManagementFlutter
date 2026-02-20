enum TaskStatus { pending, ongoing, completed }

TaskStatus taskStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return TaskStatus.pending;
    case 'ongoing':
      return TaskStatus.ongoing;
    case 'completed':
      return TaskStatus.completed;
    default:
      throw ArgumentError('Unknown TaskStatus: $value');
  }
}

String taskStatusToString(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'pending';
    case TaskStatus.ongoing:
      return 'ongoing';
    case TaskStatus.completed:
      return 'completed';
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: taskStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
