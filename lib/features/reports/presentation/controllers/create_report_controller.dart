import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';

final createReportControllerProvider =
    StateNotifierProvider<CreateReportController, AsyncValue<void>>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return CreateReportController(repository);
});

class CreateReportController extends StateNotifier<AsyncValue<void>> {
  final ReportRepository _repository;

  CreateReportController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> submitReport({
    required double latitude,
    required double longitude,
    required String description,
    required ReportSeverity severity,
    required List<String> photoUrls,
    required String reporterName,
    required String location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final input = CreateReportInput(
        photoUrls: photoUrls,
        latitude: latitude,
        longitude: longitude,
        description: description,
        severity: severity,
        reporterName: reporterName,
        location: location,
      );

      await _repository.createReport(input);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
