import '../../domain/entities/user.dart';

class UserModel extends User {
  final String? token;

  const UserModel({
    required String id,
    required String email,
    String username = '',
    String name = '',
    String plan = 'basic',
    this.token,
  }) : super(id: id, email: email, username: username, name: name, plan: plan);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      plan: json['plan'] ?? 'basic',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'plan': plan,
      'token': token,
    };
  }
}
