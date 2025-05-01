class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final String? iconName;
  final DateTime?
      completedAt; // Added this field to track when task was completed

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.isCompleted = false,
    this.iconName,
    this.completedAt, // Initialize as optional
  });

  // Added a copyWith method for easier updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    String? iconName,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      iconName: iconName ?? this.iconName,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'],
      isCompleted: json['isCompleted'] ?? false,
      iconName: json['iconName'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
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
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
