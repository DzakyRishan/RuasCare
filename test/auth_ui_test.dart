import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/presentation/screens/login_screen.dart';
import 'package:lapor_jalan/features/auth/presentation/screens/register_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child, {FakeAuthRepository? repo}) {
    final fakeRepo = repo ??
        FakeAuthRepository(
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
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders essential elements and no demo account shortcuts',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      // Nama aplikasi & Disclaimer PRD §8
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.officialDisclaimer), findsOneWidget);

      // Input field email dan password
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Masuk'), findsOneWidget);

      // Akun demo tidak lagi ditampilkan; warga mendaftar sendiri.
      expect(find.textContaining('AKUN DEMO'), findsNothing);
      expect(find.text('Warga (Budi)'), findsNothing);
      expect(find.text('Petugas (Rina)'), findsNothing);
      expect(find.text('Daftar Akun Warga'), findsOneWidget);
    });

    testWidgets('empty submission triggers form validation', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders name, email, password, and confirm password fields',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));

      expect(find.text('Buat Akun Pelapor'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('mismatched passwords trigger validation error', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));

      // Isi form dengan password tidak cocok
      await tester.enterText(find.widgetWithText(TextFormField, 'Nama Lengkap'), 'Ahmad');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ahmad@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Konfirmasi Password'), 'passwordbeda');

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);
    });
  });
}
