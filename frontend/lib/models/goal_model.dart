class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
