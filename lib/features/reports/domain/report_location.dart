/// Lokasi perangkat yang dipakai saat laporan jalan dibuat.
class ReportLocation {
  const ReportLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  /// PRD §9 meminta peringatan bila lokasi kurang akurat.
  bool get hasLowAccuracy => accuracyMeters > 100;
}
