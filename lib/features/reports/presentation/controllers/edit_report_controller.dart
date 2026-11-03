import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

final editReportControllerProvider =
    StateNotifierProvider.autoDispose<EditReportController, AsyncValue<void>>(
  (ref) => EditReportController(ref.watch(reportRepositoryProvider)),
);

class EditReportController extends StateNotifier<AsyncValue<void>> {
  EditReportController(this._repository) : super(const AsyncValue.data(null));

  final ReportRepository _repository;

  Future<bool> updateReport({
    required int reportId,
    List<String>? keepPhotoUrls,
    List<ReportPhoto> newPhotos = const [],
    double? latitude,
    double? longitude,
    String? description,
    ReportSeverity? severity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final input = UpdateReportInput(
        keepPhotoUrls: keepPhotoUrls,
        newPhotos: newPhotos,
        latitude: latitude,
        longitude: longitude,
        description: description,
        severity: severity,
      );

      if (!input.hasChanges) {
        state = const AsyncValue.data(null);
        return false;
      }

      await _repository.updateReport(reportId, input);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
