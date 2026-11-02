import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/domain/auth_repository.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';

/// State untuk proses autentikasi (login, register, logout).
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<String>> fieldErrors;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Map<String, List<String>>? fieldErrors,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }
}

/// Controller Riverpod untuk aksi autentikasi.
///
/// Layar hanya memanggil controller ini, tidak memanggil repository langsung.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// Login dengan email & password.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(isLoading: false, clearError: true);
      return user;
    } on ValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return null;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan tidak terduga. Silakan coba lagi.',
      );
      return null;
    }
  }

  /// Register akun warga baru.
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return user;
    } on ValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return null;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan tidak terduga. Silakan coba lagi.',
      );
      return null;
    }
  }

  /// Logout akun.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _repository.logout();
    state = state.copyWith(isLoading: false, clearError: true);
  }

  /// Bersihkan error state saat berpindah halaman atau input ulang.
  void clearErrors() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
