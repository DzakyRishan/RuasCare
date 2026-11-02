/// Peran pengguna (PRD §5). Nilai [apiValue] sama dengan kolom `role`
/// di tabel users (PRD §12).
enum UserRole {
  warga('CITIZEN', 'Warga'),
  petugas('OFFICER', 'Petugas');

  const UserRole(this.apiValue, this.label);

  /// Nilai mentah yang dipakai API/database.
  final String apiValue;

  /// Label untuk ditampilkan di UI.
  final String label;

  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Role tidak dikenal'),
    );
  }
}

/// Pengguna yang sedang login (response `GET /api/me`).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;

  bool get isWarga => role == UserRole.warga;
  bool get isPetugas => role == UserRole.petugas;

  User copyWith({
    int? id,
    String? name,
    String? email,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            other.id == id &&
            other.name == name &&
            other.email == email &&
            other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role);

  @override
  String toString() => 'User(id: $id, email: $email, role: ${role.apiValue})';
}
