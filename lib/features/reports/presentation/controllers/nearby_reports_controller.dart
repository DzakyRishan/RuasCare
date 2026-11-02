import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/features/reports/data/device_location_repository_provider.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
import 'package:lapor_jalan/features/reports/domain/device_location_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';

enum NearbyViewMode {
  map('Peta'),
  list('Daftar');

  const NearbyViewMode(this.label);
  final String label;
}

class NearbyReportsState {
  const NearbyReportsState({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.viewMode,
    required this.reports,
    required this.isLocating,
    required this.usesFallbackLocation,
    this.locationError,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final NearbyViewMode viewMode;
  final AsyncValue<List<Report>> reports;
  final bool isLocating;
  final bool usesFallbackLocation;
  final String? locationError;
  final double? accuracyMeters;

  NearbyReportsState copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    NearbyViewMode? viewMode,
    AsyncValue<List<Report>>? reports,
    bool? isLocating,
    bool? usesFallbackLocation,
    String? locationError,
    bool clearLocationError = false,
    double? accuracyMeters,
    bool clearAccuracy = false,
  }) {
    return NearbyReportsState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      viewMode: viewMode ?? this.viewMode,
      reports: reports ?? this.reports,
      isLocating: isLocating ?? this.isLocating,
      usesFallbackLocation: usesFallbackLocation ?? this.usesFallbackLocation,
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
      accuracyMeters: clearAccuracy ? null : (accuracyMeters ?? this.accuracyMeters),
    );
  }
}

class NearbyReportsController extends StateNotifier<NearbyReportsState> {
  NearbyReportsController(this._reportRepository, this._locationRepository)
      : super(
          const NearbyReportsState(
            latitude: AppConstants.defaultLatitude,
            longitude: AppConstants.defaultLongitude,
            radiusKm: AppConstants.defaultRadiusKm,
            viewMode: NearbyViewMode.map,
            reports: AsyncValue.loading(),
            isLocating: false,
            usesFallbackLocation: true,
          ),
        ) {
    loadCurrentLocation();
  }

  final ReportRepository _reportRepository;
  final DeviceLocationRepository _locationRepository;

  Future<void> loadCurrentLocation() async {
    state = state.copyWith(
      isLocating: true,
      clearLocationError: true,
    );

    try {
      final location = await _locationRepository.getCurrentLocation();
      state = state.copyWith(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracyMeters: location.accuracyMeters,
        usesFallbackLocation: false,
        clearLocationError: true,
      );
    } on DeviceLocationException catch (error) {
      state = state.copyWith(
        usesFallbackLocation: true,
        locationError: error.message,
        clearAccuracy: true,
      );
    } catch (_) {
      state = state.copyWith(
        usesFallbackLocation: true,
        locationError: 'Lokasi perangkat tidak dapat diambil. Menampilkan lokasi default.',
        clearAccuracy: true,
      );
    } finally {
      state = state.copyWith(isLocating: false);
    }

    await loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(reports: const AsyncValue.loading());
    try {
      final reports = await _reportRepository.getNearbyReports(
        latitude: state.latitude,
        longitude: state.longitude,
        radiusKm: state.radiusKm,
      );
      state = state.copyWith(reports: AsyncValue.data(reports));
    } catch (error, stackTrace) {
      state = state.copyWith(reports: AsyncValue.error(error, stackTrace));
    }
  }

  void setRadius(double radiusKm) {
    final clamped = radiusKm.clamp(1.0, AppConstants.maxRadiusKm).toDouble();
    if (state.radiusKm == clamped) return;
    state = state.copyWith(radiusKm: clamped);
    loadReports();
  }

  void setViewMode(NearbyViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Dipertahankan untuk test atau integrasi peta manual.
  void setLocation(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      usesFallbackLocation: false,
      clearLocationError: true,
    );
    loadReports();
  }
}

final nearbyReportsControllerProvider =
    StateNotifierProvider<NearbyReportsController, NearbyReportsState>((ref) {
  return NearbyReportsController(
    ref.watch(reportRepositoryProvider),
    ref.watch(deviceLocationRepositoryProvider),
  );
});
