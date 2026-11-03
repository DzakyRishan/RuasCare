import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_inputs.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';

ReportPhoto photo(String name) =>
    ReportPhoto(fileName: name, bytes: Uint8List.fromList([1, 2, 3]));

void main() {
  late FakeAuthRepository auth;
  late FakeReportRepository reports;

  setUp(() {
    final network = FakeNetwork(
      () => const FakeConfig(
        scenario: FakeScenario.normal,
        baseLatency: Duration.zero,
        latencyJitter: Duration.zero,
        randomFailureRate: 0,
      ),
    );
    auth = FakeAuthRepository(network: network);
    reports = FakeReportRepository(authRepository: auth, network: network);
  });

  Future<void> loginCitizen() =>
      auth.login(email: FakeUsers.budi.email, password: FakeUsers.demoPassword);

  Future<void> loginOfficer() => auth.login(
        email: FakeUsers.petugas.email,
        password: FakeUsers.demoPassword,
      );

  Future<Report> createReport() => reports.createReport(
        CreateReportInput(
          reporterName: 'Budi Santoso',
          location: 'Jl. Uji Foto',
          photos: [photo('a.jpg'), photo('b.jpg')],
          latitude: -6.175,
          longitude: 106.827,
          description: 'Lubang jalan cukup dalam di tengah lajur kiri.',
          severity: ReportSeverity.sedang,
        ),
      );

  group('Foto bukti perbaikan', () {
    test('Diperbaiki tanpa foto bukti ditolak', () async {
      await loginCitizen();
      final created = await createReport();
      await loginOfficer();
      await reports.updateReportStatus(
        created.id,
        const UpdateReportStatusInput(newStatus: ReportStatus.diverifikasi),
      );

      expect(
        () => reports.updateReportStatus(
          created.id,
          const UpdateReportStatusInput(newStatus: ReportStatus.diperbaiki),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Diperbaiki dengan foto bukti menyimpan foto dan mengubah status', () async {
      await loginCitizen();
      final created = await createReport();
      await loginOfficer();
      await reports.updateReportStatus(
        created.id,
        const UpdateReportStatusInput(newStatus: ReportStatus.diverifikasi),
      );

      final fixed = await reports.updateReportStatus(
        created.id,
        UpdateReportStatusInput(
          newStatus: ReportStatus.diperbaiki,
          repairPhotos: [photo('selesai.jpg')],
        ),
      );

      expect(fixed.status, ReportStatus.diperbaiki);
      expect(fixed.repairPhotoUrls, hasLength(1));
    });

    test('Tombol aksi nonaktif sebelum foto bukti ada', () {
      const withoutPhoto =
          UpdateReportStatusInput(newStatus: ReportStatus.diperbaiki);
      final withPhoto = UpdateReportStatusInput(
        newStatus: ReportStatus.diperbaiki,
        repairPhotos: [photo('selesai.jpg')],
      );

      expect(withoutPhoto.isComplete, isFalse);
      expect(withPhoto.isComplete, isTrue);
    });
  });

  group('Edit laporan', () {
    test('Total foto kurang dari 2 ditolak', () async {
      await loginCitizen();
      final created = await createReport();

      expect(
        () => reports.updateReport(
          created.id,
          UpdateReportInput(keepPhotoUrls: [created.photoUrls.first]),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Foto lama milik laporan lain ditolak', () async {
      await loginCitizen();
      final created = await createReport();

      expect(
        () => reports.updateReport(
          created.id,
          UpdateReportInput(
            keepPhotoUrls: [created.photoUrls.first, 'https://contoh.test/lain.jpg'],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Mempertahankan 2 foto lama dan menambah 1 foto baru menjadi 3 foto', () async {
      await loginCitizen();
      final created = await createReport();

      final updated = await reports.updateReport(
        created.id,
        UpdateReportInput(
          keepPhotoUrls: created.photoUrls,
          newPhotos: [photo('baru.jpg')],
        ),
      );

      expect(updated.photoUrls, hasLength(3));
    });
  });

  group('Ajukan ulang', () {
    Future<Report> createRejectedReport() async {
      await loginCitizen();
      final created = await createReport();
      await loginOfficer();
      await reports.updateReportStatus(
        created.id,
        const UpdateReportStatusInput.reject(reason: RejectReason.fotoTidakJelas),
      );
      await loginCitizen();
      return created;
    }

    test('Mengganti foto hanya 1 ditolak', () async {
      final rejected = await createRejectedReport();

      expect(
        () => reports.resubmitReport(
          rejected.id,
          ResubmitReportInput(photos: [photo('satu.jpg')]),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Mengganti dengan 2 foto mengembalikan status ke Dilaporkan', () async {
      final rejected = await createRejectedReport();

      final resubmitted = await reports.resubmitReport(
        rejected.id,
        ResubmitReportInput(photos: [photo('x.jpg'), photo('y.jpg')]),
      );

      expect(resubmitted.status, ReportStatus.dilaporkan);
      expect(resubmitted.photoUrls, hasLength(2));
    });
  });
}
