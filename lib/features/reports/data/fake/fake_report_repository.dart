import 'dart:math' as math;

import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/core/utils/geo.dart';
import 'package:lapor_jalan/features/auth/domain/auth_repository.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_seed.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

/// [ReportRepository] in-memory yang meniru perilaku backend Laravel.
///
/// Aturan yang ditegakkan sama dengan PRD: role per endpoint (§11),
/// kepemilikan dan status Dilaporkan untuk ubah/hapus (§7), radius dipotong
/// ke 10 km (§8), identitas pelapor tidak dikirim ke warga (§3), alasan wajib
/// saat menolak (§7), dan setiap perubahan status dicatat (§7).
class FakeReportRepository implements ReportRepository {
  FakeReportRepository({
    required AuthRepository authRepository,
    required FakeNetwork network,
    List<FakeReportRecord>? seed,
  })  : _auth = authRepository,
        _network = network,
        _records = seed ?? buildFakeReportSeed() {
    _nextReportId = _records.fold<int>(
          0,
          (maxId, record) => math.max(maxId, record.report.id),
        ) +
        1;
    _nextLogId = _records
            .expand((record) => record.report.statusHistory)
            .fold<int>(0, (maxId, log) => math.max(maxId, log.id)) +
        1;
  }

  final AuthRepository _auth;
  final FakeNetwork _network;
  final List<FakeReportRecord> _records;
  late int _nextReportId;
  late int _nextLogId;

  // ------------------------------------------------------------------ baca

  @override
  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = AppConstants.defaultRadiusKm,
  }) async {
    final viewer = await _begin(requiredRole: UserRole.warga);

    final fieldErrors = <String, List<String>>{
      ..._coordinateErrors(latitude, longitude),
      if (radiusKm <= 0) 'radius': ['Radius harus lebih dari 0 km.'],
    };
    _throwIfInvalid(fieldErrors);

    if (_network.forceEmptyLists) return const [];

    // PRD §8: parameter radius dipotong ke batas maksimal.
    final effectiveRadius = math.min(radiusKm, AppConstants.maxRadiusKm);
    final results = <Report>[];
    for (final record in _records) {
      final distance = Geo.haversineKm(
        fromLatitude: latitude,
        fromLongitude: longitude,
        toLatitude: record.report.latitude,
        toLongitude: record.report.longitude,
      );
      if (distance <= effectiveRadius) {
        results.add(_present(record, viewer, distanceKm: distance));
      }
    }
    results.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return List.unmodifiable(results);
  }

  @override
  Future<Report> getReportDetail(int id) async {
    final viewer = await _begin();
    final record = _findRecord(id);
    return _present(record, viewer, includeHistory: true);
  }

  @override
  Future<List<Report>> getMyReports() async {
    final viewer = await _begin(requiredRole: UserRole.warga);
    if (_network.forceEmptyLists) return const [];

    final results = _records
        .where((record) => record.ownerId == viewer.id)
        .map((record) => _present(record, viewer))
        .toList()
      ..sort(_newestFirst);
    return List.unmodifiable(results);
  }

  @override
  Future<List<Report>> getOfficerReports({
    ReportStatus? status,
    ReportSeverity? severity,
  }) async {
    final viewer = await _begin(requiredRole: UserRole.petugas);
    if (_network.forceEmptyLists) return const [];

    final results = _records
        .where((record) => status == null || record.report.status == status)
        .where(
          (record) => severity == null || record.report.severity == severity,
        )
        .map((record) => _present(record, viewer))
        .toList()
      ..sort(_newestFirst);
    return List.unmodifiable(results);
  }

  // ------------------------------------------------------------ tulis warga

  @override
  Future<Report> createReport(CreateReportInput input) async {
    final viewer = await _begin(requiredRole: UserRole.warga);

    final fieldErrors = <String, List<String>>{
      if (input.photos.isEmpty)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photos.length < 2)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photos.length > 3)
        'photo': ['Maksimal 3 foto per laporan.'],
      ..._coordinateErrors(input.latitude, input.longitude),
      ..._descriptionErrors(input.description),
    };
    _throwIfInvalid(fieldErrors);

    final now = DateTime.now();
    final report = Report(
      id: _nextReportId++,
      description: input.description.trim(),
      severity: input.severity,
      status: ReportStatus.dilaporkan,
      latitude: input.latitude,
      longitude: input.longitude,
      photoUrls: input.photos
          .map((photo) => _localPhotoUri(photo.fileName))
          .toList(),
      createdAt: now,
      updatedAt: now,
      statusHistory: List.unmodifiable([
        ReportStatusLog(
          id: _nextLogId++,
          fromStatus: null,
          toStatus: ReportStatus.dilaporkan,
          changedByRole: UserRole.warga,
          createdAt: now,
          note: 'Laporan dibuat.',
        ),
      ]),
    );

    final record = FakeReportRecord(
      ownerId: viewer.id,
      reporter: ReportReporter(
        id: viewer.id,
        name: viewer.name,
        email: viewer.email,
      ),
      report: report,
    );
    _records.add(record);
    return _present(record, viewer, includeHistory: true);
  }

  @override
  Future<Report> updateReport(int id, UpdateReportInput input) async {
    final viewer = await _begin(requiredRole: UserRole.warga);
    final record = _findRecord(id);
    _requireOwner(record, viewer);
    _requireStatus(
      record,
      ReportStatus.dilaporkan,
      'Laporan hanya dapat diubah saat status Dilaporkan.',
    );

    if (!input.hasChanges) {
      throw const ValidationException('Tidak ada perubahan yang dikirim.');
    }

    final latitude = input.latitude ?? record.report.latitude;
    final longitude = input.longitude ?? record.report.longitude;
    final fieldErrors = <String, List<String>>{
      if ((input.latitude == null) != (input.longitude == null))
        'location': ['Latitude dan longitude harus diubah bersamaan.'],
      ..._coordinateErrors(latitude, longitude),
      if (input.description != null) ..._descriptionErrors(input.description!),
      if (input.photoUrls != null && input.photoUrls!.isEmpty)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photoUrls != null && input.photoUrls!.length < 2)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photoUrls != null && input.photoUrls!.length > 3)
        'photo': ['Maksimal 3 foto per laporan.'],
    };
    _throwIfInvalid(fieldErrors);

    record.report = record.report.copyWith(
      description: input.description?.trim(),
      severity: input.severity,
      latitude: latitude,
      longitude: longitude,
      photoUrls:
          input.photoUrls?.map((p) => _localPhotoUri(p)).toList(),
      updatedAt: DateTime.now(),
    );
    return _present(record, viewer, includeHistory: true);
  }

  @override
  Future<void> deleteReport(int id) async {
    final viewer = await _begin(requiredRole: UserRole.warga);
    final record = _findRecord(id);
    _requireOwner(record, viewer);
    _requireStatus(
      record,
      ReportStatus.dilaporkan,
      'Laporan hanya dapat dihapus saat status Dilaporkan.',
    );
    _records.remove(record);
  }

  @override
  Future<Report> resubmitReport(int id, ResubmitReportInput input) async {
    final viewer = await _begin(requiredRole: UserRole.warga);
    final record = _findRecord(id);
    _requireOwner(record, viewer);
    _requireStatus(
      record,
      ReportStatus.ditolak,
      'Hanya laporan berstatus Ditolak yang dapat diajukan ulang.',
    );

    if (!input.hasNewContent) {
      throw const ValidationException(
        'Sertakan foto atau keterangan baru untuk mengajukan ulang.',
        fieldErrors: {
          'description': ['Isi keterangan baru atau lampirkan foto baru.'],
        },
      );
    }
    final newDescription = input.description?.trim();
    final fieldErrors = <String, List<String>>{
      if (newDescription != null && newDescription.isNotEmpty)
        ..._descriptionErrors(newDescription),
      if (input.photoUrls != null && input.photoUrls!.isEmpty)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photoUrls != null && input.photoUrls!.length < 2)
        'photo': ['Minimal 2 foto wajib dilampirkan.'],
      if (input.photoUrls != null && input.photoUrls!.length > 3)
        'photo': ['Maksimal 3 foto per laporan.'],
    };
    _throwIfInvalid(fieldErrors);

    final now = DateTime.now();
    record.report = record.report.copyWith(
      status: ReportStatus.dilaporkan,
      description: (newDescription == null || newDescription.isEmpty)
          ? null
          : newDescription,
      photoUrls:
          input.photoUrls?.map((p) => _localPhotoUri(p)).toList(),
      clearRejection: true,
      updatedAt: now,
      statusHistory: _appendLog(
        record,
        from: ReportStatus.ditolak,
        to: ReportStatus.dilaporkan,
        role: UserRole.warga,
        at: now,
        note: 'Diajukan ulang oleh pelapor.',
      ),
    );
    return _present(record, viewer, includeHistory: true);
  }

  // ---------------------------------------------------------- tulis petugas

  @override
  Future<Report> updateReportStatus(
    int id,
    UpdateReportStatusInput input,
  ) async {
    final viewer = await _begin(requiredRole: UserRole.petugas);
    final record = _findRecord(id);
    final current = record.report.status;
    final target = input.newStatus;

    if (!current.canOfficerChangeTo(target)) {
      throw ValidationException(
        'Status tidak dapat diubah dari ${current.label} ke ${target.label}.',
        fieldErrors: {
          'status': ['Perubahan status tidak diizinkan.'],
        },
      );
    }

    final note = input.note?.trim();
    final fieldErrors = <String, List<String>>{
      if (target == ReportStatus.ditolak && input.rejectReason == null)
        'reject_reason': ['Alasan penolakan wajib dipilih.'],
      if (note != null && note.length > AppConstants.statusNoteMaxLength)
        'note': [
          'Catatan maksimal ${AppConstants.statusNoteMaxLength} karakter.',
        ],
    };
    _throwIfInvalid(fieldErrors);

    final normalizedNote = (note == null || note.isEmpty) ? null : note;
    final now = DateTime.now();
    final history = _appendLog(
      record,
      from: current,
      to: target,
      role: viewer.role,
      at: now,
      note: normalizedNote,
    );

    record.report = target == ReportStatus.ditolak
        ? record.report.copyWith(
            status: target,
            rejectReason: input.rejectReason,
            rejectNote: normalizedNote,
            updatedAt: now,
            statusHistory: history,
          )
        : record.report.copyWith(
            status: target,
            clearRejection: true,
            updatedAt: now,
            statusHistory: history,
          );
    return _present(record, viewer, includeHistory: true);
  }

  // ---------------------------------------------------------------- helper

  /// Simulasi jaringan lalu cek login dan role, seperti middleware Laravel.
  Future<User> _begin({UserRole? requiredRole}) async {
    await _network.simulate();
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedException();
    if (requiredRole != null && user.role != requiredRole) {
      throw const ForbiddenException();
    }
    return user;
  }

  FakeReportRecord _findRecord(int id) {
    for (final record in _records) {
      if (record.report.id == id) return record;
    }
    throw const NotFoundException('Laporan tidak ditemukan.');
  }

  void _requireOwner(FakeReportRecord record, User viewer) {
    if (record.ownerId != viewer.id) {
      throw const ForbiddenException(
        'Anda hanya dapat mengelola laporan milik sendiri.',
      );
    }
  }

  void _requireStatus(
    FakeReportRecord record,
    ReportStatus expected,
    String message,
  ) {
    if (record.report.status != expected) {
      throw ValidationException(message);
    }
  }

  /// Membentuk respons sesuai penampil.
  ///
  /// Identitas pelapor hanya untuk petugas (PRD §3, §8, §17). Riwayat status
  /// hanya disertakan pada respons detail/mutasi, seperti API nanti.
  Report _present(
    FakeReportRecord record,
    User viewer, {
    double? distanceKm,
    bool includeHistory = false,
  }) {
    return record.report.copyWith(
      isMine: record.ownerId == viewer.id,
      distanceKm: distanceKm,
      clearDistance: distanceKm == null,
      reporter: viewer.isPetugas ? record.reporter : null,
      clearReporter: !viewer.isPetugas,
      statusHistory: includeHistory ? record.report.statusHistory : const [],
    );
  }

  List<ReportStatusLog> _appendLog(
    FakeReportRecord record, {
    required ReportStatus from,
    required ReportStatus to,
    required UserRole role,
    required DateTime at,
    String? note,
  }) {
    return List.unmodifiable([
      ...record.report.statusHistory,
      ReportStatusLog(
        id: _nextLogId++,
        fromStatus: from,
        toStatus: to,
        changedByRole: role,
        createdAt: at,
        note: note,
      ),
    ]);
  }

  Map<String, List<String>> _coordinateErrors(
    double latitude,
    double longitude,
  ) {
    return {
      if (!Geo.isValidLatitude(latitude)) 'lat': ['Latitude tidak valid.'],
      if (!Geo.isValidLongitude(longitude)) 'lng': ['Longitude tidak valid.'],
    };
  }

  Map<String, List<String>> _descriptionErrors(String description) {
    final length = description.trim().length;
    if (length < AppConstants.descriptionMinLength) {
      return {
        'description': [
          'Deskripsi minimal ${AppConstants.descriptionMinLength} karakter.',
        ],
      };
    }
    if (length > AppConstants.descriptionMaxLength) {
      return {
        'description': [
          'Deskripsi maksimal ${AppConstants.descriptionMaxLength} karakter.',
        ],
      };
    }
    return const {};
  }

  void _throwIfInvalid(Map<String, List<String>> fieldErrors) {
    if (fieldErrors.isEmpty) return;
    throw ValidationException(
      fieldErrors.values.first.first,
      fieldErrors: Map.unmodifiable(fieldErrors),
    );
  }

  static int _newestFirst(Report a, Report b) =>
      b.createdAt.compareTo(a.createdAt);

  /// Fake tidak meng-upload file, jadi foto lokal dirujuk sebagai URI file.
  static String _localPhotoUri(String path) => Uri.file(path).toString();
}
