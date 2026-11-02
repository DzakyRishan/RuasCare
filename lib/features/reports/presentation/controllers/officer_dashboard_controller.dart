import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';

final officerDashboardControllerProvider =
    StateNotifierProvider<OfficerDashboardController, AsyncValue<List<Report>>>(
  (ref) => OfficerDashboardController(ref.watch(reportRepositoryProvider)),
);

class OfficerDashboardController extends StateNotifier<AsyncValue<List<Report>>> {
  OfficerDashboardController(this._repository) : super(const AsyncValue.loading()) {
    loadReports();
  }

  final ReportRepository _repository;
  ReportStatus? _statusFilter;
  ReportSeverity? _severityFilter;

  Future<void> loadReports({ReportStatus? status, ReportSeverity? severity}) async {
    _statusFilter = status;
    _severityFilter = severity;
    state = const AsyncValue.loading();
    try {
      final reports = await _repository.getOfficerReports(
        status: _statusFilter,
        severity: _severityFilter,
      );
      state = AsyncValue.data(reports);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus({
    required int reportId,
    required ReportStatus newStatus,
    RejectReason? rejectReason,
    String? note,
  }) async {
    try {
      await _repository.updateReportStatus(
        reportId,
        UpdateReportStatusInput(
          newStatus: newStatus,
          rejectReason: rejectReason,
          note: note,
        ),
      );
      await loadReports(status: _statusFilter, severity: _severityFilter);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
