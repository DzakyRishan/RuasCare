import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/officer_dashboard_controller.dart';

void main() {
  FakeNetwork immediateNetwork() {
    return FakeNetwork(
      () => const FakeConfig(
        scenario: FakeScenario.normal,
        baseLatency: Duration.zero,
        latencyJitter: Duration.zero,
        randomFailureRate: 0,
      ),
    );
  }

  test('Petugas can verify a reported report from the dashboard controller', () async {
    final authRepository = FakeAuthRepository(network: immediateNetwork());
    await authRepository.login(
      email: FakeUsers.petugas.email,
      password: FakeUsers.demoPassword,
    );
    final reportRepository = FakeReportRepository(
      authRepository: authRepository,
      network: immediateNetwork(),
    );
    final controller = OfficerDashboardController(reportRepository);
    addTearDown(controller.dispose);

    await controller.loadReports(status: ReportStatus.dilaporkan);
    final reports = controller.state.value!;
    final reportId = reports.first.id;

    await controller.updateStatus(
      reportId: reportId,
      newStatus: ReportStatus.diverifikasi,
      note: 'Laporan diperiksa oleh petugas.',
    );

    await controller.loadReports();
    final updatedReport = controller.state.value!.firstWhere(
      (report) => report.id == reportId,
    );
    expect(updatedReport.status, ReportStatus.diverifikasi);
  });
}
