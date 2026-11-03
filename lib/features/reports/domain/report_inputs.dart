import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';

/// Data untuk `POST /api/reports` (multipart).
class CreateReportInput {
  const CreateReportInput({
    required this.photos,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.severity,
    required this.reporterName,
    required this.location,
  });

  /// Byte foto hasil pemilihan Kamera/Galeri yang siap diunggah.
  final List<ReportPhoto> photos;
  final double latitude;
  final double longitude;
  final String description;
  final ReportSeverity severity;
  final String reporterName;
  final String location;
}

/// Data untuk `PUT /api/reports/{id}` (multipart). Field null berarti tidak
/// diubah.
///
/// Foto diubah dengan dua daftar: [keepPhotoUrls] untuk foto lama yang tetap
/// dipakai dan [newPhotos] untuk foto baru. Totalnya harus 2-3 foto.
class UpdateReportInput {
  const UpdateReportInput({
    this.keepPhotoUrls,
    this.newPhotos = const [],
    this.latitude,
    this.longitude,
    this.description,
    this.severity,
  });

  final List<String>? keepPhotoUrls;
  final List<ReportPhoto> newPhotos;
  final double? latitude;
  final double? longitude;
  final String? description;
  final ReportSeverity? severity;

  bool get hasPhotoChanges => keepPhotoUrls != null || newPhotos.isNotEmpty;

  bool get hasChanges =>
      hasPhotoChanges ||
      latitude != null ||
      longitude != null ||
      description != null ||
      severity != null;
}

/// Data untuk `POST /api/reports/{id}/resubmit` (multipart).
///
/// PRD §6: pengajuan ulang disertai foto atau keterangan baru, jadi minimal
/// salah satu harus diisi. Jika foto diganti, jumlahnya 2-3 foto.
class ResubmitReportInput {
  const ResubmitReportInput({this.photos = const [], this.description});

  final List<ReportPhoto> photos;
  final String? description;

  bool get hasNewContent =>
      photos.isNotEmpty || (description != null && description!.trim().isNotEmpty);
}

/// Data untuk `PUT /api/reports/{id}/status` (khusus petugas).
///
/// Status Diperbaiki wajib disertai [repairPhotos] sebagai bukti, dikirim
/// lewat `POST /api/reports/{id}/fix`.
class UpdateReportStatusInput {
  const UpdateReportStatusInput({
    required this.newStatus,
    this.rejectReason,
    this.note,
    this.repairPhotos = const [],
  });

  /// Shortcut untuk penolakan; alasan wajib (PRD §7).
  const UpdateReportStatusInput.reject({
    required RejectReason reason,
    this.note,
  })  : newStatus = ReportStatus.ditolak,
        rejectReason = reason,
        repairPhotos = const [];

  final ReportStatus newStatus;

  /// Wajib bila [newStatus] = [ReportStatus.ditolak].
  final RejectReason? rejectReason;

  /// Catatan singkat; dicatat juga di riwayat status.
  final String? note;

  /// Foto bukti perbaikan. Wajib 1-3 foto bila [newStatus] =
  /// [ReportStatus.diperbaiki].
  final List<ReportPhoto> repairPhotos;

  /// Dipakai UI untuk menonaktifkan tombol sebelum syarat status terpenuhi
  /// (PRD §7). Server tetap memvalidasi ulang.
  bool get isComplete {
    if (newStatus == ReportStatus.ditolak) return rejectReason != null;
    if (newStatus == ReportStatus.diperbaiki) {
      return repairPhotos.isNotEmpty && repairPhotos.length <= 3;
    }
    return true;
  }
}
