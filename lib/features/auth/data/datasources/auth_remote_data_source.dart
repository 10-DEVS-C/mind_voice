import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
  Future<UserModel> register(String username, String email, String password, String name);
  Future<UserModel> updateProfile({
    required String token,
    required String userId,
    required String username,
    required String email,
    required String name,
    required String plan,
  });
  Future<String> changePlanRole({
    required String token,
    required String userId,
    required String planKey,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://18.223.30.63:5000';

  AuthRemoteDataSourceImpl({required this.client});

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          if (response.statusCode == 401) {
            return 'Usuario o contrasena incorrectos';
          }
          if (response.statusCode == 409) {
            return 'El usuario ya existe';
          }
          return message;
        }
      }
    } catch (_) {
      // Ignora errores al parsear el body.
    }

    if (response.statusCode == 401) {
      return 'Usuario o contrasena incorrectos';
    }
    if (response.statusCode == 409) {
      return 'El usuario ya existe';
    }

    return fallback;
  }

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      // Decode the token to get user ID
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId =
          decodedToken['sub'] ?? 'unknown_id'; // Fallback if sub is missing

      final role = (decodedToken['role'] ?? 'user').toString().toLowerCase();
      final plan = role == 'admin' || role == 'premium' || role == 'pro'
          ? 'premium'
          : 'basic';

      String resolvedUsername = username;
      String resolvedEmail = username;
      String resolvedName = decodedToken['name']?.toString() ?? '';

      try {
        final profileResponse = await client.get(
          Uri.parse('$baseUrl/users/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          resolvedUsername =
              profileData['username']?.toString() ?? resolvedUsername;
          resolvedEmail = profileData['email']?.toString() ?? resolvedEmail;
          resolvedName = profileData['name']?.toString() ?? resolvedName;
        }
      } catch (_) {
        // Si falla, seguimos con datos del token/login.
      }

      return UserModel(
        id: userId,
        email: resolvedEmail,
        username: resolvedUsername,
        name: resolvedName,
        plan: plan,
        token: token,
      );
    } else {
      throw ServerException(
        _extractErrorMessage(response, 'No se pudo iniciar sesion'),
      );
    }
  }

  @override
  Future<UserModel> register(String username, String email, String password, String name) async {
    // 1. Crear usuario en POST /users/
    final regResponse = await client.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (regResponse.statusCode != 201 && regResponse.statusCode != 200) {
      throw ServerException(
        _extractErrorMessage(regResponse, 'No se pudo registrar el usuario'),
      );
    }

    // 2. Auto-login para obtener token
    return await login(username, password);
  }

  @override
  Future<UserModel> updateProfile({
    required String token,
    required String userId,
    required String username,
    required String email,
    required String name,
    required String plan,
  }) async {
    final response = await client.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel(
        id: data['_id']?.toString() ?? userId,
        email: data['email']?.toString() ?? email,
        username: data['username']?.toString() ?? username,
        name: data['name']?.toString() ?? name,
        plan: plan,
        token: token,
      );
    }

    throw ServerException(
      _extractErrorMessage(response, 'No se pudo actualizar el perfil'),
    );
  }

  @override
  Future<String> changePlanRole({
    required String token,
    required String userId,
    required String planKey,
  }) async {
    // 1. Obtener todos los roles
    final rolesResponse = await client.get(
      Uri.parse('$baseUrl/roles/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (rolesResponse.statusCode != 200) {
      throw ServerException('No se pudieron cargar los roles');
    }

    final List<dynamic> roles = jsonDecode(rolesResponse.body);

    // 2. Buscar rol con name == "User" y permissions.plan == planKey
    String? roleId;
    for (final role in roles.whereType<Map<String, dynamic>>()) {
      final roleName = (role['name'] ?? '').toString().toLowerCase();
      if (roleName != 'user') continue;

      final permissions = role['permissions'];
      if (permissions is Map) {
        final planPerm = (permissions['plan'] ?? '').toString().toLowerCase();
        final normalized = planKey.toLowerCase();
        final matches = planPerm == normalized ||
            (normalized == 'professional' &&
                (planPerm == 'pro' || planPerm == 'professional'));
        if (matches) {
          roleId = role['_id']?.toString();
          break;
        }
      }
    }

    if (roleId == null || roleId.isEmpty) {
      throw ServerException('No se encontró el rol para el plan $planKey');
    }

    // 3. Actualizar el roleId del usuario
    final updateResponse = await client.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'roleId': roleId}),
    );

    if (updateResponse.statusCode != 200) {
      throw ServerException(
        _extractErrorMessage(updateResponse, 'No se pudo actualizar el plan'),
      );
    }

    return planKey;
  }
}
