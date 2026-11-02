import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';

/// Kontrak data laporan, satu method per endpoint di PRD §11.
///
/// Semua method melempar turunan [AppException] bila gagal. Implementasi
/// wajib menegakkan aturan yang sama dengan backend (role, kepemilikan,
/// status), bukan hanya mengandalkan UI.
abstract interface class ReportRepository {
  /// `GET /api/reports?lat=&lng=&radius=` (warga).
  ///
  /// [radiusKm] dipotong ke [AppConstants.maxRadiusKm]. Hasil tidak memuat
  /// identitas pelapor dan terurut dari yang terdekat.
  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = AppConstants.defaultRadiusKm,
  });

  /// `GET /api/reports/{id}` (login). Termasuk riwayat status.
  /// Melempar [NotFoundException] bila tidak ada.
  Future<Report> getReportDetail(int id);

  /// `GET /api/my-reports` (warga). Tanpa batas radius (PRD §8),
  /// terurut dari yang terbaru.
  Future<List<Report>> getMyReports();

  /// `POST /api/reports` (warga).
  Future<Report> createReport(CreateReportInput input);

  /// `PUT /api/reports/{id}` (warga pemilik, hanya status Dilaporkan).
  Future<Report> updateReport(int id, UpdateReportInput input);

  /// `DELETE /api/reports/{id}` (warga pemilik, hanya status Dilaporkan).
  Future<void> deleteReport(int id);

  /// `POST /api/reports/{id}/resubmit` (warga pemilik, hanya status
  /// Ditolak). Status kembali ke Dilaporkan.
  Future<Report> resubmitReport(int id, ResubmitReportInput input);

  /// `GET /api/officer/reports?status=&severity=` (petugas). Tanpa batas
  /// radius, terurut dari yang terbaru, memuat identitas pelapor.
  Future<List<Report>> getOfficerReports({
    ReportStatus? status,
    ReportSeverity? severity,
  });

  /// `PATCH /api/reports/{id}/status` (petugas). Alasan wajib bila Ditolak.
  Future<Report> updateReportStatus(int id, UpdateReportStatusInput input);
}
