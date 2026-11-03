import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_seed.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/officer_dashboard_screen.dart';

/// Memastikan Petugas benar-benar melihat dan dapat memakai aksi status dari
/// layar dashboard (bukan hanya dari controller).
void main() {
  testWidgets(
    'Petugas menekan status Dilaporkan lalu melihat pilihan Tolak dan Verifikasi',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final network = FakeNetwork(
        () => const FakeConfig(
          scenario: FakeScenario.normal,
          baseLatency: Duration.zero,
          latencyJitter: Duration.zero,
          randomFailureRate: 0,
        ),
      );
      final auth = FakeAuthRepository(network: network);
      // testWidgets memakai waktu palsu; login (Future.delayed) harus berjalan
      // di zona asli, kalau tidak test menggantung.
      await tester.runAsync(
        () => auth.login(
          email: FakeUsers.petugas.email,
          password: FakeUsers.demoPassword,
        ),
      );
      // Satu laporan tanpa foto: Image.network tidak pernah selesai di test
      // dan membuat test menggantung, padahal yang diuji adalah tombol status.
      final now = DateTime(2026, 11, 3);
      final reports = FakeReportRepository(
        authRepository: auth,
        network: network,
        seed: [
          FakeReportRecord(
            ownerId: FakeUsers.budi.id,
            reporter: ReportReporter(
              id: FakeUsers.budi.id,
              name: FakeUsers.budi.name,
              email: FakeUsers.budi.email,
            ),
            report: Report(
              id: 1,
              description: 'Lubang besar di lajur kiri jalan utama.',
              severity: ReportSeverity.sedang,
              status: ReportStatus.dilaporkan,
              latitude: -6.1754,
              longitude: 106.8272,
              photoUrls: const [],
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [reportRepositoryProvider.overrideWithValue(reports)],
          child: const MaterialApp(home: OfficerDashboardScreen()),
        ),
      );
      // Beri waktu loading data tanpa pumpAndSettle (gambar jaringan tidak selesai).
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Dashboard Petugas'), findsOneWidget);

      // Chip status berstatus Dilaporkan harus ada dan dapat ditekan.
      final statusChip = find.widgetWithText(ActionChip, ReportStatus.dilaporkan.label);
      expect(statusChip, findsWidgets);

      await tester.ensureVisible(statusChip.first);
      await tester.tap(statusChip.first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ubah Status Laporan'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Verifikasi'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Tolak'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  testWidgets(
    'Laporan Diverifikasi: tombol Tandai Diperbaiki nonaktif sampai ada foto bukti',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final network = FakeNetwork(
        () => const FakeConfig(
          scenario: FakeScenario.normal,
          baseLatency: Duration.zero,
          latencyJitter: Duration.zero,
          randomFailureRate: 0,
        ),
      );
      final auth = FakeAuthRepository(network: network);
      await tester.runAsync(
        () => auth.login(
          email: FakeUsers.petugas.email,
          password: FakeUsers.demoPassword,
        ),
      );

      final now = DateTime(2026, 11, 3);
      final reports = FakeReportRepository(
        authRepository: auth,
        network: network,
        seed: [
          FakeReportRecord(
            ownerId: FakeUsers.budi.id,
            reporter: ReportReporter(
              id: FakeUsers.budi.id,
              name: FakeUsers.budi.name,
              email: FakeUsers.budi.email,
            ),
            report: Report(
              id: 1,
              description: 'Aspal amblas di depan gedung perkantoran.',
              severity: ReportSeverity.parah,
              status: ReportStatus.diverifikasi,
              latitude: -6.1754,
              longitude: 106.8272,
              photoUrls: const [],
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [reportRepositoryProvider.overrideWithValue(reports)],
          child: const MaterialApp(home: OfficerDashboardScreen()),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final statusChip = find.widgetWithText(ActionChip, ReportStatus.diverifikasi.label);
      expect(statusChip, findsOneWidget);
      await tester.tap(statusChip);
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog pilihan status: hanya Tandai Diperbaiki yang tersedia.
      expect(find.widgetWithText(FilledButton, 'Tandai Diperbaiki'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Verifikasi'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Tandai Diperbaiki'));
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog bukti perbaikan: tombol konfirmasi mati tanpa foto.
      expect(find.text('Foto bukti perbaikan (1-3 foto, wajib)'), findsOneWidget);
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tandai Diperbaiki'),
      );
      expect(confirmButton.onPressed, isNull);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
