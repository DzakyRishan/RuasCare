import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';

/// Kontrak autentikasi (PRD §11: register, login, logout, me).
///
/// Semua method melempar turunan [AppException] bila gagal.
abstract interface class AuthRepository {
  /// Pengguna yang sedang login, atau null. Dibaca sinkron oleh router.
  User? get currentUser;

  /// Memancarkan [currentUser] saat ini begitu di-listen, lalu setiap kali
  /// berubah (login, logout, sesi kedaluwarsa).
  Stream<User?> authStateChanges();

  /// Memulihkan sesi dari token tersimpan saat app dibuka (`GET /api/me`).
  /// Mengembalikan null bila tidak ada sesi yang valid.
  Future<User?> restoreSession();

  /// `POST /api/login`. Melempar [ValidationException] bila kredensial salah.
  Future<User> login({required String email, required String password});

  /// `POST /api/register`. Akun baru selalu ber-role warga (PRD §11).
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  /// `POST /api/logout`. Sesi lokal tetap dihapus walau request gagal.
  Future<void> logout();

  /// Menghapus sesi lokal tanpa memanggil server, dipakai saat menerima
  /// [UnauthorizedException] (PRD §9: token kedaluwarsa -> ke login).
  Future<void> clearSession();
}
