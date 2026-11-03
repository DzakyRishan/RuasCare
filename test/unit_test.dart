import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/core/router/route_guard.dart';
import 'package:lapor_jalan/core/utils/geo.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';

void main() {
  group('Geo Utility', () {
    test('Haversine distance calculation is accurate', () {
      // Jarak Monas ke Bundaran HI (~2.3 km)
      final distance = Geo.haversineKm(
        fromLatitude: -6.175392,
        fromLongitude: 106.827153,
        toLatitude: -6.195000,
        toLongitude: 106.823000,
      );
      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(2.5));
    });
  });

  group('Route Guard', () {
    test('Unauthenticated user is redirected to login', () {
      final redirect = resolveRedirect(
        user: null,
        location: AppRoutes.nearbyReports,
      );
      expect(redirect, equals(AppRoutes.login));
    });

    test('Warga is redirected away from officer routes', () {
      final redirect = resolveRedirect(
        user: FakeUsers.budi,
        location: AppRoutes.officerReports,
      );
      expect(redirect, equals(AppRoutes.nearbyReports));
    });

    test('Petugas is redirected away from citizen routes', () {
      final redirect = resolveRedirect(
        user: FakeUsers.petugas,
        location: AppRoutes.nearbyReports,
      );
      expect(redirect, equals(AppRoutes.officerReports));
    });

    test('Authenticated user visiting login is redirected to role home', () {
      final redirect = resolveRedirect(
        user: FakeUsers.budi,
        location: AppRoutes.login,
      );
      expect(redirect, equals(AppRoutes.nearbyReports));
    });
  });

  group('FakeAuthRepository', () {
    late FakeAuthRepository authRepo;

    setUp(() {
      authRepo = FakeAuthRepository(
        network: FakeNetwork(
          () => const FakeConfig(
            scenario: FakeScenario.normal,
            baseLatency: Duration.zero,
            latencyJitter: Duration.zero,
            randomFailureRate: 0,
          ),
        ),
      );
    });

    test('Login with valid credentials succeeds', () async {
      final user = await authRepo.login(
        email: FakeUsers.budi.email,
        password: FakeUsers.demoPassword,
      );
      expect(user.id, equals(FakeUsers.budi.id));
      expect(authRepo.currentUser, equals(user));
    });

    test('Login with wrong password throws ValidationException', () async {
      expect(
        () => authRepo.login(
          email: FakeUsers.budi.email,
          password: 'wrongpassword',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Register creates citizen account and sets session', () async {
      final newUser = await authRepo.register(
        name: 'User Baru',
        email: 'baru@demo.id',
        password: 'password123',
      );
      expect(newUser.role, equals(UserRole.warga));
      expect(authRepo.currentUser, equals(newUser));
    });
  });

  group('FakeReportRepository', () {
    late FakeAuthRepository authRepo;
    late FakeReportRepository reportRepo;

    setUp(() {
      final network = FakeNetwork(
        () => const FakeConfig(
          scenario: FakeScenario.normal,
          baseLatency: Duration.zero,
          latencyJitter: Duration.zero,
          randomFailureRate: 0,
        ),
      );
      authRepo = FakeAuthRepository(network: network);
      reportRepo = FakeReportRepository(
        authRepository: authRepo,
        network: network,
      );
    });

    test('Nearby reports enforces 10 km max radius and hides reporter info for citizen', () async {
      await authRepo.login(
        email: FakeUsers.budi.email,
        password: FakeUsers.demoPassword,
      );

      final reports = await reportRepo.getNearbyReports(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        radiusKm: 25, // Di atas 10 km
      );

      // Semua laporan di radius <= 10 km
      for (final r in reports) {
        expect(r.distanceKm, lessThanOrEqualTo(AppConstants.maxRadiusKm));
        // PRD §3 & §8: Response publik tidak memuat identitas pelapor
        expect(r.reporter, isNull);
      }
    });

    test('Officer reports include reporter identity', () async {
      await authRepo.login(
        email: FakeUsers.petugas.email,
        password: FakeUsers.demoPassword,
      );

      final reports = await reportRepo.getOfficerReports();
      expect(reports.isNotEmpty, isTrue);
      // Petugas dapat melihat reporter
      expect(reports.first.reporter, isNotNull);
    });

    test('Rejecting report without reason throws ValidationException', () async {
      await authRepo.login(
        email: FakeUsers.petugas.email,
        password: FakeUsers.demoPassword,
      );

      expect(
        () => reportRepo.updateReportStatus(
          1,
          const UpdateReportStatusInput(
            newStatus: ReportStatus.ditolak,
            rejectReason: null, // Tanpa alasan
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Citizen can create report and see it in myReports', () async {
      await authRepo.login(
        email: FakeUsers.budi.email,
        password: FakeUsers.demoPassword,
      );

      final created = await reportRepo.createReport(
        CreateReportInput(
          reporterName: 'Budi Santoso',
          location: 'Jl. Jendral Sudirman',
          photos: [
            ReportPhoto(fileName: 'photo1.jpg', bytes: Uint8List.fromList([1])),
            ReportPhoto(fileName: 'photo2.jpg', bytes: Uint8List.fromList([2])),
          ],
          latitude: -6.175000,
          longitude: 106.827000,
          description: 'Jalan berlubang parah di depan halte busway.',
          severity: ReportSeverity.parah,
        ),
      );

      expect(created.status, equals(ReportStatus.dilaporkan));
      expect(created.isMine, isTrue);

      final myReports = await reportRepo.getMyReports();
      expect(myReports.any((r) => r.id == created.id), isTrue);
    });
  });
}
