import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/nearby_reports_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/nearby_map_view.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_card.dart';

/// Layar utama warga: Peta dan Daftar Laporan di Sekitar (PRD §6 & §8).
class NearbyReportsScreen extends ConsumerWidget {
  const NearbyReportsScreen({super.key});

  static const List<double> _radiusOptions = [2.0, 5.0, 10.0];

  void _navigateToDetail(BuildContext context, Report report) {
    context.go(AppRoutes.reportDetailPath(report.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final state = ref.watch(nearbyReportsControllerProvider);
    final controller = ref.read(nearbyReportsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentUser != null)
              Text(
                'Halo, ${currentUser.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perbarui lokasi GPS',
            icon: state.isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: state.isLocating ? null : controller.loadCurrentLocation,
          ),
          // Navigasi ke Laporan Saya (PRD §6)
          IconButton(
            tooltip: 'Laporan Saya',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => context.go(AppRoutes.myReports),
          ),
          // Menu Logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Keluar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Toggle Mode Tampilan (Peta vs Daftar)
                  SegmentedButton<NearbyViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: NearbyViewMode.map,
                        icon: Icon(Icons.map_outlined, size: 16),
                        label: Text('Peta'),
                      ),
                      ButtonSegment(
                        value: NearbyViewMode.list,
                        icon: Icon(Icons.format_list_bulleted, size: 16),
                        label: Text('Daftar'),
                      ),
                    ],
                    selected: {state.viewMode},
                    onSelectionChanged: (selected) {
                      controller.setViewMode(selected.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filter Radius (PRD §8)
                  Text(
                    'Radius:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._radiusOptions.map((r) {
                    final isSelected = state.radiusKm == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('${r.toInt()} km'),
                        selected: isSelected,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => controller.setRadius(r),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      body: state.reports.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat laporan sekitar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error.toString().replaceFirst(RegExp(r'^[a-zA-Z]+Exception:\s*'), ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.loadReports,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada jalan rusak di sekitar sini',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dalam radius ${state.radiusKm.toInt()} km tidak ditemukan laporan jalan rusak aktif.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (state.radiusKm < AppConstants.maxRadiusKm) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            controller.setRadius(AppConstants.maxRadiusKm),
                        icon: const Icon(Icons.zoom_out_map, size: 18),
                        label: const Text('Perbesar Radius ke 10 km'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (state.viewMode == NearbyViewMode.map) {
            return NearbyMapView(
              userLatitude: state.latitude,
              userLongitude: state.longitude,
              radiusKm: state.radiusKm,
              reports: reports,
              onReportSelected: (report) => _navigateToDetail(context, report),
              onRefreshLocation: controller.loadCurrentLocation,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadReports,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return ReportCard(
                  report: report,
                  onTap: () => _navigateToDetail(context, report),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.createReport),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Laporkan Jalan'),
      ),
    );
  }
}
