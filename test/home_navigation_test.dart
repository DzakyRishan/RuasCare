import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/home_screen.dart';

/// Memastikan setiap menu di beranda Warga menuju rute yang benar-benar ada,
/// bukan halaman "Page Not Found".
void main() {
  Future<GoRouter> pumpHome(WidgetTester tester) async {
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
        email: FakeUsers.budi.email,
        password: FakeUsers.demoPassword,
      ),
    );

    final visited = <String>[];
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        for (final path in [
          AppRoutes.createReport,
          AppRoutes.myReports,
          AppRoutes.nearbyReports,
        ])
          GoRoute(
            path: path,
            builder: (context, state) {
              visited.add(path);
              return Scaffold(body: Text('halaman $path'));
            },
          ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('Beranda menampilkan nama aplikasi dan menu utama', (tester) async {
    await pumpHome(tester);

    expect(find.text('RUASCARE.'), findsOneWidget);
    expect(find.text('Buat Laporan'), findsOneWidget);
    expect(find.text('Laporan Saya'), findsOneWidget);
    expect(find.text('Peta Sekitar'), findsOneWidget);
    expect(find.text('Bantuan'), findsOneWidget);
  });

  testWidgets('Menu Buat Laporan, Laporan Saya, dan Peta menuju rute yang ada', (tester) async {
    for (final entry in {
      'Buat Laporan': AppRoutes.createReport,
      'Laporan Saya': AppRoutes.myReports,
      'Peta Sekitar': AppRoutes.nearbyReports,
    }.entries) {
      await pumpHome(tester);
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('halaman ${entry.value}'), findsOneWidget, reason: entry.key);
    }
  });

  testWidgets('Tombol Lapor Cepat menuju form Buat Laporan', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.bolt));
    await tester.pumpAndSettle();

    expect(find.text('halaman ${AppRoutes.createReport}'), findsOneWidget);
  });

  testWidgets('Bantuan membuka panduan, bukan halaman tidak ditemukan', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Bantuan'));
    await tester.pumpAndSettle();

    expect(find.text('Cara Memakai RuasCare'), findsOneWidget);
    expect(find.text(AppConstants.officialDisclaimer), findsOneWidget);
  });
}
