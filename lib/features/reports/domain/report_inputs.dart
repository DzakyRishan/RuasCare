import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

/// Data untuk `POST /api/reports` (multipart).
class CreateReportInput {
  const CreateReportInput({
    required this.photoUrls,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.severity,
    required this.reporterName,
    required this.location,
  });

  /// Daftar path file foto lokal yang sudah dikompres (PRD §9, 2-3 foto).
  final List<String> photoUrls;
  final double latitude;
  final double longitude;
  final String description;
  final ReportSeverity severity;
  final String reporterName;
  final String location;
}

/// Data untuk `PUT /api/reports/{id}`. Field null berarti tidak diubah.
class UpdateReportInput {
  const UpdateReportInput({
    this.photoUrls,
    this.latitude,
    this.longitude,
    this.description,
    this.severity,
  });

  final List<String>? photoUrls;
  final double? latitude;
  final double? longitude;
  final String? description;
  final ReportSeverity? severity;

  bool get hasChanges =>
      photoUrls != null ||
      latitude != null ||
      longitude != null ||
      description != null ||
      severity != null;
}

/// Data untuk `POST /api/reports/{id}/resubmit`.
///
/// PRD §6: pengajuan ulang disertai foto atau keterangan baru, jadi minimal
/// salah satu harus diisi.
class ResubmitReportInput {
  const ResubmitReportInput({this.photoUrls, this.description});

  final List<String>? photoUrls;
  final String? description;

  bool get hasNewContent =>
      (photoUrls != null && photoUrls!.isNotEmpty) ||
      (description != null && description!.trim().isNotEmpty);
}

/// Data untuk `PATCH /api/reports/{id}/status` (khusus petugas).
class UpdateReportStatusInput {
  const UpdateReportStatusInput({
    required this.newStatus,
    this.rejectReason,
    this.note,
  });

  /// Shortcut untuk penolakan; alasan wajib (PRD §7).
  const UpdateReportStatusInput.reject({
    required RejectReason reason,
    this.note,
  })  : newStatus = ReportStatus.ditolak,
        rejectReason = reason;

  final ReportStatus newStatus;

  /// Wajib bila [newStatus] = [ReportStatus.ditolak].
  final RejectReason? rejectReason;

  /// Catatan singkat; dicatat juga di riwayat status.
  final String? note;

  /// Dipakai UI untuk menonaktifkan tombol tolak sebelum alasan diisi
  /// (PRD §7). Server tetap memvalidasi ulang.
  bool get isComplete =>
      newStatus != ReportStatus.ditolak || rejectReason != null;
}
