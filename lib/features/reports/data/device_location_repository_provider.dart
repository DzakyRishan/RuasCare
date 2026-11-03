import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/data/geolocator_device_location_repository.dart';
import 'package:lapor_jalan/features/reports/domain/device_location_repository.dart';

final deviceLocationRepositoryProvider = Provider<DeviceLocationRepository>(
  (ref) => GeolocatorDeviceLocationRepository(),
);
