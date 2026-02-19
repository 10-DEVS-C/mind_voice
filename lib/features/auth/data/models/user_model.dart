import '../../domain/entities/user.dart';

class UserModel extends User {
  final String? token;

  const UserModel({required String id, required String email, this.token})
    : super(id: id, email: email);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'token': token};
  }
}
