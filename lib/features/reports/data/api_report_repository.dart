import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

/// Implementasi [ReportRepository] yang connect ke Spring Boot backend.
class ApiReportRepository implements ReportRepository {
  ApiReportRepository({
    required FlutterSecureStorage secureStorage,
    required Dio dio,
    String baseUrl = 'http://localhost:8080',
  })  : _storage = secureStorage,
        _dio = dio,
        _baseUrl = baseUrl;

  final FlutterSecureStorage _storage;
  final Dio _dio;
  final String _baseUrl;

  Future<String> _getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    return token ?? '';
  }

  @override
  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = AppConstants.defaultRadiusKm,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl/api/reports/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
        },
        options: Options(headers: headers),
      );

      final List<dynamic> data = response.data;
      return data.map((json) => _mapFromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Report> getReportDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl/api/reports/$id',
        options: Options(headers: headers),
      );
      return _mapFromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<List<Report>> getMyReports() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl/api/reports/my-reports',
        options: Options(headers: headers),
      );

      final List<dynamic> data = response.data;
      return data.map((json) => _mapFromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Report> createReport(CreateReportInput input) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '$_baseUrl/api/reports',
        data: FormData.fromMap({
          'description': input.description,
          'severity': input.severity.name.toUpperCase(),
          'latitude': input.latitude,
          'longitude': input.longitude,
          'locationName': input.location,
          'photos': input.photos
              .map(
                (photo) => MultipartFile.fromBytes(
                  photo.bytes,
                  filename: photo.fileName,
                ),
              )
              .toList(),
        }),
        options: Options(headers: headers),
      );
      return _mapFromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Report> updateReport(int id, UpdateReportInput input) async {
    try {
      final headers = await _getHeaders();
      final data = <String, dynamic>{};
      if (input.description != null) data['description'] = input.description;
      if (input.severity != null) data['severity'] = input.severity!.name.toUpperCase();
      if (input.latitude != null) data['latitude'] = input.latitude;
      if (input.longitude != null) data['longitude'] = input.longitude;
      if (input.photoUrls != null) data['photoUrls'] = input.photoUrls;

      final response = await _dio.put(
        '$_baseUrl/api/reports/$id',
        data: data,
        options: Options(headers: headers),
      );
      return _mapFromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteReport(int id) async {
    try {
      final headers = await _getHeaders();
      await _dio.delete(
        '$_baseUrl/api/reports/$id',
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Report> resubmitReport(int id, ResubmitReportInput input) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '$_baseUrl/api/reports/$id/resubmit',
        data: {
          if (input.description != null) 'description': input.description,
          if (input.photoUrls != null) 'photoUrls': input.photoUrls,
        },
        options: Options(headers: headers),
      );
      return _mapFromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Report>> getOfficerReports({
    ReportStatus? status,
    ReportSeverity? severity,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl/api/officer/reports',
        queryParameters: {
          if (status != null) 'status': status.name.toUpperCase(),
          if (severity != null) 'severity': severity.name.toUpperCase(),
        },
        options: Options(headers: headers),
      );

      final List<dynamic> data = response.data;
      return data.map((json) => _mapFromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Report> updateReportStatus(int id, UpdateReportStatusInput input) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.put(
        '$_baseUrl/api/reports/$id/status',
        data: {
          'newStatus': input.newStatus.name.toUpperCase(),
          if (input.rejectReason != null)
            'rejectReason': _rejectReasonToApi(input.rejectReason!),
          if (input.note != null) 'note': input.note,
        },
        options: Options(headers: headers),
      );
      return _mapFromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Report _mapFromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      severity: ReportSeverity.values.firstWhere(
        (e) => e.name.toLowerCase() == json['severity'].toString().toLowerCase(),
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
      ),
      photoUrls: List<String>.from(json['photoUrls'] ?? [])
          .map(_resolvePhotoUrl)
          .toList(),
      rejectReason: json['rejectReason'] != null
          ? _rejectReasonFromApi(json['rejectReason'].toString())
          : null,
      rejectNote: json['rejectNote'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isMine: json['isMine'] == true,
      distanceKm: json['distanceKm'],
      reporter: json['reporter'] is Map<String, dynamic>
          ? ReportReporter(
              id: json['reporter']['id'],
              name: json['reporter']['name'],
              email: json['reporter']['email'],
            )
          : null,
      statusHistory: _mapStatusHistory(json['statusHistory']),
    );
  }

  String _resolvePhotoUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$_baseUrl$value';
  }

  List<ReportStatusLog> _mapStatusHistory(dynamic rawHistory) {
    final history = rawHistory is List ? rawHistory : const [];
    return history.map((rawItem) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      return ReportStatusLog(
        id: item['id'],
        fromStatus: item['fromStatus'] == null
            ? null
            : ReportStatus.values.firstWhere(
                (status) =>
                    status.name.toLowerCase() ==
                    item['fromStatus'].toString().toLowerCase(),
              ),
        toStatus: ReportStatus.values.firstWhere(
          (status) =>
              status.name.toLowerCase() == item['toStatus'].toString().toLowerCase(),
        ),
        changedByRole: UserRole.fromApiValue(item['changedByRole'].toString()),
        note: item['note'],
        createdAt: DateTime.parse(item['createdAt'].toString()),
      );
    }).toList();
  }

  String _rejectReasonToApi(RejectReason reason) {
    return switch (reason) {
      RejectReason.duplikat => 'DUPLIKAT',
      RejectReason.bukanJalanRusak => 'BUKAN_KERUSAKAN_JALAN',
      RejectReason.fotoTidakJelas => 'FOTO_TIDAK_JELAS',
      RejectReason.lokasiTidakSesuai => 'LOKASI_TIDAK_VALID',
    };
  }

  RejectReason _rejectReasonFromApi(String value) {
    return switch (value) {
      'DUPLIKAT' => RejectReason.duplikat,
      'BUKAN_KERUSAKAN_JALAN' => RejectReason.bukanJalanRusak,
      'FOTO_TIDAK_JELAS' => RejectReason.fotoTidakJelas,
      'LOKASI_TIDAK_VALID' => RejectReason.lokasiTidakSesuai,
      _ => throw ArgumentError.value(value, 'value', 'Alasan penolakan tidak dikenal'),
    };
  }

  AppException _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return const UnauthorizedException();
    } else if (e.response?.statusCode == 403) {
      return const ForbiddenException();
    } else if (e.response?.statusCode == 404) {
      return const NotFoundException('Laporan tidak ditemukan');
    } else if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('errors')) {
        return ValidationException(
          'Data tidak valid',
          fieldErrors: Map<String, List<String>>.from(data['errors']),
        );
      }
      return ValidationException(data?['message'] ?? 'Request tidak valid');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Koneksi timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return NetworkException('Tidak dapat terhubung ke server');
    }
    return NetworkException(e.message ?? 'Terjadi kesalahan jaringan');
  }
}
