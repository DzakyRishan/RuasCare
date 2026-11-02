/// Konstanta global aplikasi yang diturunkan langsung dari PRD.
abstract final class AppConstants {
  /// Nama kerja sementara. PRD §17: nama aplikasi masih open question.
  static const String appName = 'RuasCare';

  /// PRD §8: app wajib menyatakan bukan kanal resmi pemerintah.
  static const String officialDisclaimer =
      'Aplikasi ini adalah perantara pihak ketiga dan bukan kanal resmi '
      'pemerintah.';

  /// PRD §8: radius default saat app dibuka.
  static const double defaultRadiusKm = 5;

  /// PRD §8: radius maksimal untuk warga (dipaksakan juga di backend).
  static const double maxRadiusKm = 10;

  /// PRD §9: lokasi default peta bila izin lokasi ditolak (Monas, Jakarta).
  static const double defaultLatitude = -6.175392;
  static const double defaultLongitude = 106.827153;

  /// Panjang deskripsi laporan yang diterima (disamakan dengan validasi server).
  static const int descriptionMinLength = 10;
  static const int descriptionMaxLength = 1000;

  /// Panjang maksimal catatan penolakan / perubahan status.
  static const int statusNoteMaxLength = 255;
}
