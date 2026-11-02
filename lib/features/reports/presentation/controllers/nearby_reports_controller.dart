import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';
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
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final NearbyViewMode viewMode;
  final AsyncValue<List<Report>> reports;

  NearbyReportsState copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    NearbyViewMode? viewMode,
    AsyncValue<List<Report>>? reports,
  }) {
    return NearbyReportsState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      viewMode: viewMode ?? this.viewMode,
      reports: reports ?? this.reports,
    );
  }
}

class NearbyReportsController extends StateNotifier<NearbyReportsState> {
  NearbyReportsController(this._repository)
      : super(
          const NearbyReportsState(
            latitude: AppConstants.defaultLatitude,
            longitude: AppConstants.defaultLongitude,
            radiusKm: AppConstants.defaultRadiusKm,
            viewMode: NearbyViewMode.map,
            reports: AsyncValue.loading(),
          ),
        ) {
    loadReports();
  }

  final ReportRepository _repository;

  Future<void> loadReports() async {
    state = state.copyWith(reports: const AsyncValue.loading());
    try {
      final reports = await _repository.getNearbyReports(
        latitude: state.latitude,
        longitude: state.longitude,
        radiusKm: state.radiusKm,
      );
      state = state.copyWith(reports: AsyncValue.data(reports));
    } catch (e, st) {
      state = state.copyWith(reports: AsyncValue.error(e, st));
    }
  }

  void setRadius(double radiusKm) {
    final clamped = radiusKm.clamp(1.0, AppConstants.maxRadiusKm);
    if (state.radiusKm == clamped) return;
    state = state.copyWith(radiusKm: clamped);
    loadReports();
  }

  void setViewMode(NearbyViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
    loadReports();
  }
}

final nearbyReportsControllerProvider =
    StateNotifierProvider<NearbyReportsController, NearbyReportsState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return NearbyReportsController(repository);
});
