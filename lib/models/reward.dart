class Reward {
  final String id;
  final String title;
  final int pointsRequired;

  Reward({required this.id, required this.title, required this.pointsRequired});

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'],
      pointsRequired: json['pointsRequired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'pointsRequired': pointsRequired};
  }
}
