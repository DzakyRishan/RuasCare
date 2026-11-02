import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/report_detail_screen.dart';

void main() {
  testWidgets('ReportDetailScreen renders description, status, and timeline',
      (tester) async {
    final network = FakeNetwork(
      () => const FakeConfig(
        scenario: FakeScenario.normal,
        baseLatency: Duration.zero,
        latencyJitter: Duration.zero,
        randomFailureRate: 0,
      ),
    );
    final authRepo = FakeAuthRepository(network: network);
    await authRepo.login(
      email: FakeUsers.budi.email,
      password: FakeUsers.demoPassword,
    );

    final repRepo = FakeReportRepository(
      authRepository: authRepo,
      network: network,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          reportRepositoryProvider.overrideWithValue(repRepo),
        ],
        child: const MaterialApp(
          home: ReportDetailScreen(reportId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Judul AppBar
    expect(find.text('Detail Laporan #1'), findsOneWidget);

    // Section Headers
    expect(find.text('Deskripsi Kerusakan'), findsOneWidget);
    expect(find.text('Titik Lokasi Kerusakan'), findsOneWidget);
    expect(find.text('Riwayat Tindak Lanjut'), findsOneWidget);
  });
}
