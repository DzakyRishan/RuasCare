import 'package:lapor_jalan/features/reports/domain/report_location.dart';

/// Abstraksi lokasi perangkat agar layar dan controller tidak bergantung
/// langsung pada plugin GPS tertentu.
abstract interface class DeviceLocationRepository {
  Future<ReportLocation> getCurrentLocation();
}

sealed class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class DeviceLocationServiceDisabledException
    extends DeviceLocationException {
  const DeviceLocationServiceDisabledException()
      : super('GPS atau layanan lokasi perangkat sedang tidak aktif.');
}

final class LocationPermissionDeniedException extends DeviceLocationException {
  const LocationPermissionDeniedException()
      : super('Izin lokasi diperlukan untuk mengirim laporan.');
}

final class LocationPermissionPermanentlyDeniedException
    extends DeviceLocationException {
  const LocationPermissionPermanentlyDeniedException()
      : super('Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.');
}

final class LocationTimeoutException extends DeviceLocationException {
  const LocationTimeoutException()
      : super('Lokasi belum dapat ditemukan. Coba lagi di area dengan sinyal GPS lebih baik.');
}

final class LocationUnavailableException extends DeviceLocationException {
  const LocationUnavailableException()
      : super('Lokasi perangkat tidak tersedia. Silakan coba lagi.');
}
