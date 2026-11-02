import 'package:lapor_jalan/features/auth/domain/user.dart';

/// Akun mock beserta password-nya. Hanya hidup di Fake repository.
class FakeAccount {
  const FakeAccount({required this.user, required this.password});

  final User user;
  final String password;
}

/// Akun demo yang di-seed ke [FakeAuthRepository] dan direferensikan oleh
/// data laporan mock sebagai pemilik laporan.
///
/// Semua password demo: `password123`.
abstract final class FakeUsers {
  static const String demoPassword = 'password123';

  /// Warga dengan beberapa laporan di berbagai status, termasuk satu laporan
  /// di luar radius 10 km (tetap muncul di "Laporan Saya", PRD §8).
  static const User budi = User(
    id: 1,
    name: 'Budi Santoso',
    email: 'budi@demo.id',
    role: UserRole.warga,
  );

  /// Warga lain, pemilik sebagian laporan di sekitar.
  static const User siti = User(
    id: 2,
    name: 'Siti Rahmawati',
    email: 'siti@demo.id',
    role: UserRole.warga,
  );

  /// Warga tanpa laporan sama sekali (uji empty state "Laporan Saya").
  static const User andi = User(
    id: 3,
    name: 'Andi Pratama',
    email: 'andi@demo.id',
    role: UserRole.warga,
  );

  /// Akun demo petugas (PRD §5).
  static const User petugas = User(
    id: 4,
    name: 'Rina Wulandari',
    email: 'petugas@demo.id',
    role: UserRole.petugas,
  );

  static List<FakeAccount> get accounts => const [
        FakeAccount(user: budi, password: demoPassword),
        FakeAccount(user: siti, password: demoPassword),
        FakeAccount(user: andi, password: demoPassword),
        FakeAccount(user: petugas, password: demoPassword),
      ];
}
