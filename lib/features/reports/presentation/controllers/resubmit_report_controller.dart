import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

final resubmitReportControllerProvider =
    StateNotifierProvider.autoDispose<ResubmitReportController, AsyncValue<void>>(
  (ref) => ResubmitReportController(ref.watch(reportRepositoryProvider)),
);

class ResubmitReportController extends StateNotifier<AsyncValue<void>> {
  ResubmitReportController(this._repository) : super(const AsyncValue.data(null));

  final ReportRepository _repository;

  Future<bool> resubmitReport({
    required int reportId,
    List<ReportPhoto> photos = const [],
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final input = ResubmitReportInput(
        photos: photos,
        description: description,
      );

      if (!input.hasNewContent) {
        state = const AsyncValue.data(null);
        return false;
      }

      await _repository.resubmitReport(reportId, input);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
