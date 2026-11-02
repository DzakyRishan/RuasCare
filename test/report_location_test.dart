import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_jalan/features/reports/domain/report_location.dart';

void main() {
  test('GPS accuracy at or below 100 meters is accepted', () {
    final location = ReportLocation(
      latitude: -6.175392,
      longitude: 106.827153,
      accuracyMeters: 100,
      capturedAt: DateTime(2026),
    );

    expect(location.hasLowAccuracy, isFalse);
  });

  test('GPS accuracy above 100 meters requires a warning', () {
    final location = ReportLocation(
      latitude: -6.175392,
      longitude: 106.827153,
      accuracyMeters: 101,
      capturedAt: DateTime(2026),
    );

    expect(location.hasLowAccuracy, isTrue);
  });
}
