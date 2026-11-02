import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/features/auth/domain/auth_repository.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';

/// Implementasi [AuthRepository] yang connect ke Spring Boot backend.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
    String baseUrl = 'http://localhost:8080',
  })  : _dio = dio,
        _storage = secureStorage,
        _baseUrl = baseUrl;

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  User? _currentUser;
  final StreamController<User?> _controller = StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  /// Ambil JWT token dari secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  @override
  Future<User?> restoreSession() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      // Coba fetch user info dari /api/auth/me
      final response = await _dio.get(
        '$_baseUrl/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _currentUser = _mapUserFromJson(response.data);
      _controller.add(_currentUser);
      return _currentUser;
    } catch (e) {
      // Token invalid atau expired, clear session
      await clearSession();
      return null;
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['token'] as String;
      final user = _mapUserFromJson(data);

      // Simpan token dan user info
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: user.id.toString());
      await _storage.write(key: _userNameKey, value: user.name);
      await _storage.write(key: _userEmailKey, value: user.email);
      await _storage.write(key: _userRoleKey, value: user.role.apiValue);

      _currentUser = user;
      _controller.add(_currentUser);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final token = data['token'] as String;
      final user = _mapUserFromJson(data);

      // Simpan token dan user info
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: user.id.toString());
      await _storage.write(key: _userNameKey, value: user.name);
      await _storage.write(key: _userEmailKey, value: user.email);
      await _storage.write(key: _userRoleKey, value: user.role.apiValue);

      _currentUser = user;
      _controller.add(_currentUser);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          '$_baseUrl/api/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      // Ignore error, clear session anyway
    } finally {
      await clearSession();
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userRoleKey);

    _currentUser = null;
    _controller.add(null);
  }

  User _mapUserFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.fromApiValue(json['role']),
    );
  }

  AppException _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return const UnauthorizedException();
    } else if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('errors')) {
        return ValidationException(
          'Data tidak valid',
          fieldErrors: Map<String, List<String>>.from(data['errors']),
        );
      }
      return ValidationException(data?['message'] ?? 'Request tidak valid');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Koneksi timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('Tidak dapat terhubung ke server');
    }
    return NetworkException(e.message ?? 'Terjadi kesalahan jaringan');
  }

  void dispose() {
    _controller.close();
  }
}
