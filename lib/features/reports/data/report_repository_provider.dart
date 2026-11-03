import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/reports/data/api_report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

/// Provider untuk Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return dio;
});

/// Titik tunggal penyedia [ReportRepository].
///
/// Terhubung ke Spring Boot backend di [AppConstants.apiBaseUrl].
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository(
    secureStorage: ref.watch(secureStorageProvider),
    dio: ref.watch(dioProvider),
    baseUrl: AppConstants.apiBaseUrl,
  );
});
