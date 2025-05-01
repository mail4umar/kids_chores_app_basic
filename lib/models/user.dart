import 'user_type.dart';

class User {
  final String id;
  final String name;
  final String avatar;
  final UserType userType;

  User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == json['userType'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'userType': userType.toString(),
    };
  }
}
