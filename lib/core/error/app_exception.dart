/// Semua error yang boleh keluar dari repository.
///
/// Layar hanya perlu menangani tipe-tipe ini, tidak peduli apakah sumbernya
/// Fake repository atau API Laravel. Implementasi API nanti memetakan status
/// HTTP ke tipe di bawah (401 -> [UnauthorizedException], 403 ->
/// [ForbiddenException], 404 -> [NotFoundException], 422 ->
/// [ValidationException], 5xx -> [ServerException], timeout/socket ->
/// [NetworkException]).
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Pesan yang aman ditampilkan langsung ke pengguna.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Tidak ada internet, timeout, atau upload gagal. PRD §9: tampilkan tombol
/// coba lagi dan jangan hilangkan isian form.
final class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Tidak dapat terhubung ke server. Periksa koneksi internet '
        'lalu coba lagi.',
  ]);
}

/// Server mengalami kesalahan internal.
final class ServerException extends AppException {
  const ServerException([
    super.message = 'Terjadi kesalahan pada server. Coba lagi beberapa saat '
        'lagi.',
  ]);
}

/// Token tidak ada atau kedaluwarsa. PRD §9: arahkan kembali ke login.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Sesi Anda telah berakhir. Silakan login kembali.',
  ]);
}

/// Pengguna login tetapi tidak berhak (role salah atau bukan pemilik).
final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'Anda tidak memiliki akses untuk tindakan ini.',
  ]);
}

/// Data yang diminta tidak ditemukan.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan.']);
}

/// Input ditolak oleh aturan bisnis atau validasi (setara HTTP 422 Laravel).
final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
  });

  /// Error per field, mengikuti format `errors` milik Laravel.
  final Map<String, List<String>> fieldErrors;

  /// Pesan error pertama untuk [field], atau null bila field tersebut valid.
  String? errorFor(String field) {
    final errors = fieldErrors[field];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }
}
