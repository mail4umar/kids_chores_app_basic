class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final String? iconName;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.isCompleted = false,
    this.iconName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'],
      isCompleted: json['isCompleted'] ?? false,
      iconName: json['iconName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isCompleted': isCompleted,
      'iconName': iconName,
    };
  }
}
