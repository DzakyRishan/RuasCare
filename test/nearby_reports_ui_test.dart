import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/nearby_reports_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_card.dart';

void main() {
  Widget buildTestableWidget({
    required FakeAuthRepository authRepo,
    FakeReportRepository? reportRepo,
  }) {
    final repRepo = reportRepo ??
        FakeReportRepository(
          authRepository: authRepo,
          network: FakeNetwork(
            () => const FakeConfig(
              scenario: FakeScenario.normal,
              baseLatency: Duration.zero,
              latencyJitter: Duration.zero,
              randomFailureRate: 0,
            ),
          ),
        );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        reportRepositoryProvider.overrideWithValue(repRepo),
      ],
      child: const MaterialApp(
        home: NearbyReportsScreen(),
      ),
    );
  }

  testWidgets('NearbyReportsScreen renders toggle, radius chips, and floating button',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authRepo = FakeAuthRepository(
      network: FakeNetwork(
        () => const FakeConfig(
          scenario: FakeScenario.normal,
          baseLatency: Duration.zero,
          latencyJitter: Duration.zero,
          randomFailureRate: 0,
        ),
      ),
    );
    await authRepo.login(
      email: FakeUsers.budi.email,
      password: FakeUsers.demoPassword,
    );

    await tester.pumpWidget(buildTestableWidget(authRepo: authRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // App bar title & FAB
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Laporkan Jalan'), findsOneWidget);

    // SegmentedButton toggle (Peta & Daftar)
    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);

    // Filter Radius Chips (PRD §8: 2 km, 5 km, 10 km)
    expect(find.text('2 km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
  });

  testWidgets('switching to list mode renders ReportCards', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authRepo = FakeAuthRepository(
      network: FakeNetwork(
        () => const FakeConfig(
          scenario: FakeScenario.normal,
          baseLatency: Duration.zero,
          latencyJitter: Duration.zero,
          randomFailureRate: 0,
        ),
      ),
    );
    await authRepo.login(
      email: FakeUsers.budi.email,
      password: FakeUsers.demoPassword,
    );

    await tester.pumpWidget(buildTestableWidget(authRepo: authRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Klik tab 'Daftar'
    await tester.tap(find.text('Daftar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dalam mode daftar, Card laporan ter-render
    expect(find.byType(ReportCard), findsWidgets);
  });
}
