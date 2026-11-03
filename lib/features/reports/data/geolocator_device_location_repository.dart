import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:lapor_jalan/features/reports/domain/device_location_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_location.dart';

/// Implementasi lokasi perangkat Android/Web menggunakan Geolocator.
class GeolocatorDeviceLocationRepository implements DeviceLocationRepository {
  @override
  Future<ReportLocation> getCurrentLocation() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const DeviceLocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return ReportLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: DateTime.now(),
      );
    } on TimeoutException {
      throw const LocationTimeoutException();
    } catch (_) {
      throw const LocationUnavailableException();
    }
  }
}
