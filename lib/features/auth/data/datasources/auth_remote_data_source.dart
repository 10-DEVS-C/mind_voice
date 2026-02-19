import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://18.223.30.63:5000';

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      // Decode the token to get user ID
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId =
          decodedToken['sub'] ?? 'unknown_id'; // Fallback if sub is missing

      return UserModel(id: userId, email: email, token: token);
    } else {
      throw ServerException('Failed to login: ${response.body}');
    }
  }

  @override
  Future<UserModel> register(String email, String password) async {
    // Implement similar logic for register if needed, or keeping it mock/TODO for now as the prompt focused on login.
    // However, interface requires it.
    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw ServerException('Failed to register: ${response.body}');
    }
  }
}
