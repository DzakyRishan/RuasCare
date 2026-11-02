import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';

final myReportsControllerProvider =
    AsyncNotifierProvider<MyReportsController, List<Report>>(
  MyReportsController.new,
);

class MyReportsController extends AsyncNotifier<List<Report>> {
  late final ReportRepository _repository = ref.watch(reportRepositoryProvider);

  @override
  Future<List<Report>> build() async {
    return _repository.getMyReports();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getMyReports());
  }

  Future<bool> deleteReport(int id) async {
    try {
      await _repository.deleteReport(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
