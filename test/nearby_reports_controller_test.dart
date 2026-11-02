import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/core/fake/fake_network.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_auth_repository.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/reports/data/fake/fake_report_repository.dart';
import 'package:lapor_jalan/features/reports/domain/device_location_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_location.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/nearby_reports_controller.dart';

class FixedLocationRepository implements DeviceLocationRepository {
  const FixedLocationRepository(this.location);

  final ReportLocation location;

  @override
  Future<ReportLocation> getCurrentLocation() async => location;
}

void main() {
  test('nearby map uses the device GPS coordinates', () async {
    final network = FakeNetwork(
      () => const FakeConfig(
        scenario: FakeScenario.normal,
        baseLatency: Duration.zero,
        latencyJitter: Duration.zero,
        randomFailureRate: 0,
      ),
    );
    final authRepository = FakeAuthRepository(network: network);
    await authRepository.login(
      email: FakeUsers.budi.email,
      password: FakeUsers.demoPassword,
    );
    final reportRepository = FakeReportRepository(
      authRepository: authRepository,
      network: network,
    );
    final controller = NearbyReportsController(
      reportRepository,
      FixedLocationRepository(
        ReportLocation(
          latitude: -7.79558,
          longitude: 110.36949,
          accuracyMeters: 12,
          capturedAt: DateTime(2026),
        ),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadCurrentLocation();

    expect(controller.state.latitude, -7.79558);
    expect(controller.state.longitude, 110.36949);
    expect(controller.state.accuracyMeters, 12);
    expect(controller.state.usesFallbackLocation, isFalse);
  });
}
