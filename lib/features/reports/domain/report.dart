import 'package:lapor_jalan/features/auth/domain/user.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

/// Identitas pelapor. Hanya terisi pada respons untuk petugas
/// (PRD §17, usulan: petugas boleh melihat identitas pelapor).
///
/// Untuk respons publik/warga selalu null (PRD §3 dan §8).
class ReportReporter {
  const ReportReporter({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;
}

/// Satu baris riwayat perubahan status (tabel `report_status_logs`, PRD §12).
class ReportStatusLog {
  const ReportStatusLog({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.changedByRole,
    required this.createdAt,
    this.note,
  });

  final int id;

  /// Null untuk entri pertama saat laporan dibuat.
  final ReportStatus? fromStatus;
  final ReportStatus toStatus;

  /// Peran pengubah status. Nama pengubah tidak dikirim ke app agar riwayat
  /// aman ditampilkan ke publik.
  final UserRole changedByRole;
  final DateTime createdAt;
  final String? note;
}

/// Laporan jalan rusak (tabel `reports`, PRD §12).
///
/// Sengaja tidak memuat `user_id`: respons publik tidak boleh memuat
/// identitas pelapor (PRD §3). Kepemilikan ditentukan oleh endpoint
/// (`/api/my-reports`) dan ditandai lewat [isMine].
class Report {
  const Report({
    required this.id,
    required this.description,
    required this.severity,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
    this.rejectReason,
    this.rejectNote,
    this.repairPhotoUrls = const [],
    this.isMine = false,
    this.distanceKm,
    this.reporter,
    this.statusHistory = const [],
  });

  final int id;
  final String description;
  final ReportSeverity severity;
  final ReportStatus status;
  final double latitude;
  final double longitude;

  /// Daftar URL foto dari server atau file lokal.
  final List<String> photoUrls;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Terisi hanya bila [status] = [ReportStatus.ditolak] (PRD §7).
  final RejectReason? rejectReason;
  final String? rejectNote;

  /// Foto bukti perbaikan dari petugas. Terisi saat status Diperbaiki.
  final List<String> repairPhotoUrls;

  /// True bila laporan milik pengguna yang sedang login.
  final bool isMine;

  /// Jarak dari titik pencarian. Hanya terisi pada daftar laporan sekitar.
  final double? distanceKm;

  /// Hanya terisi untuk petugas. Lihat [ReportReporter].
  final ReportReporter? reporter;

  /// Riwayat status terurut dari yang paling lama. Bisa kosong pada respons
  /// daftar; selalu terisi pada respons detail.
  final List<ReportStatusLog> statusHistory;

  /// PRD §7: warga hanya dapat mengubah/menghapus saat status Dilaporkan.
  bool get canOwnerEditOrDelete =>
      isMine && status == ReportStatus.dilaporkan;

  /// PRD §6: warga dapat mengajukan ulang laporan yang ditolak.
  bool get canOwnerResubmit => isMine && status == ReportStatus.ditolak;

  bool get isRejected => status == ReportStatus.ditolak;

  Report copyWith({
    String? description,
    ReportSeverity? severity,
    ReportStatus? status,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    RejectReason? rejectReason,
    String? rejectNote,
    bool clearRejection = false,
    List<String>? repairPhotoUrls,
    bool? isMine,
    double? distanceKm,
    bool clearDistance = false,
    ReportReporter? reporter,
    bool clearReporter = false,
    List<ReportStatusLog>? statusHistory,
  }) {
    return Report(
      id: id,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectReason:
          clearRejection ? null : (rejectReason ?? this.rejectReason),
      rejectNote: clearRejection ? null : (rejectNote ?? this.rejectNote),
      repairPhotoUrls: repairPhotoUrls ?? this.repairPhotoUrls,
      isMine: isMine ?? this.isMine,
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      reporter: clearReporter ? null : (reporter ?? this.reporter),
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  String toString() =>
      'Report(id: $id, status: ${status.apiValue}, severity: '
      '${severity.apiValue})';
}
