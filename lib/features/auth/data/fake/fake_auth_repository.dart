import 'dart:async';

import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/auth/domain/auth_repository.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';

/// [AuthRepository] in-memory untuk pengembangan sebelum backend siap.
///
/// Aturan validasi meniru yang akan diterapkan Laravel (PRD §13) agar layar
/// sudah menangani error yang sama sejak awal.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required FakeNetwork network,
    List<FakeAccount>? accounts,
  })  : _network = network,
        _accounts = List.of(accounts ?? FakeUsers.accounts);

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const int _minPasswordLength = 8;

  final FakeNetwork _network;
  final List<FakeAccount> _accounts;
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<User?> restoreSession() async {
    // Fake tidak punya penyimpanan token permanen, sehingga sesi hanya
    // bertahan selama app berjalan.
    if (_currentUser == null) {
      await _network.simulate(requiresAuth: false);
      return null;
    }
    try {
      await _network.simulate();
      return _currentUser;
    } on UnauthorizedException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    await _network.simulate(requiresAuth: false);

    final normalizedEmail = email.trim().toLowerCase();
    final fieldErrors = <String, List<String>>{
      if (normalizedEmail.isEmpty) 'email': ['Email wajib diisi.'],
      if (password.isEmpty) 'password': ['Password wajib diisi.'],
    };
    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Periksa kembali isian Anda.',
        fieldErrors: fieldErrors,
      );
    }

    final account = _findAccount(normalizedEmail);
    if (account == null || account.password != password) {
      throw const ValidationException(
        'Email atau password salah.',
        fieldErrors: {
          'email': ['Email atau password salah.'],
        },
      );
    }

    _setUser(account.user);
    return account.user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _network.simulate(requiresAuth: false);

    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final fieldErrors = <String, List<String>>{};

    if (trimmedName.isEmpty) {
      fieldErrors['name'] = ['Nama wajib diisi.'];
    } else if (trimmedName.length > 100) {
      fieldErrors['name'] = ['Nama maksimal 100 karakter.'];
    }

    if (normalizedEmail.isEmpty) {
      fieldErrors['email'] = ['Email wajib diisi.'];
    } else if (!_emailPattern.hasMatch(normalizedEmail)) {
      fieldErrors['email'] = ['Format email tidak valid.'];
    } else if (_findAccount(normalizedEmail) != null) {
      fieldErrors['email'] = ['Email sudah terdaftar.'];
    }

    if (password.length < _minPasswordLength) {
      fieldErrors['password'] = [
        'Password minimal $_minPasswordLength karakter.',
      ];
    }

    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Periksa kembali isian Anda.',
        fieldErrors: fieldErrors,
      );
    }

    final nextId = _accounts
            .map((account) => account.user.id)
            .fold<int>(0, (max, id) => id > max ? id : max) +
        1;
    final user = User(
      id: nextId,
      name: trimmedName,
      email: normalizedEmail,
      role: UserRole.warga,
    );
    _accounts.add(FakeAccount(user: user, password: password));
    _setUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _network.simulate();
    } on AppException {
      // PRD: logout lokal tetap dijalankan walau request ke server gagal.
    } finally {
      await clearSession();
    }
  }

  @override
  Future<void> clearSession() async {
    _setUser(null);
  }

  /// Menutup stream. Dipanggil saat provider dibuang.
  void dispose() {
    _controller.close();
  }

  FakeAccount? _findAccount(String normalizedEmail) {
    for (final account in _accounts) {
      if (account.user.email == normalizedEmail) return account;
    }
    return null;
  }

  void _setUser(User? user) {
    if (_currentUser == user) return;
    _currentUser = user;
    if (!_controller.isClosed) _controller.add(user);
  }
}
