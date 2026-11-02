import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lapor_jalan/core/theme/app_colors.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_badges.dart';

/// Tampilan peta OpenStreetMap untuk laporan sekitar (PRD §6 & §8).
class NearbyMapView extends StatefulWidget {
  const NearbyMapView({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    required this.radiusKm,
    required this.reports,
    required this.onReportSelected,
  });

  final double userLatitude;
  final double userLongitude;
  final double radiusKm;
  final List<Report> reports;
  final ValueChanged<Report> onReportSelected;

  @override
  State<NearbyMapView> createState() => _NearbyMapViewState();
}

class _NearbyMapViewState extends State<NearbyMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _severityColor(ReportSeverity severity) {
    return switch (severity) {
      ReportSeverity.ringan => AppColors.severityRingan,
      ReportSeverity.sedang => AppColors.severitySedang,
      ReportSeverity.parah => AppColors.severityParah,
    };
  }

  void _showReportBottomSheet(BuildContext context, Report report) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Image.network(
                          report.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ReportSeverityBadge(severity: report.severity),
                              const SizedBox(width: 6),
                              ReportStatusChip(
                                status: report.status,
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (report.distanceKm != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${report.distanceKm!.toStringAsFixed(1)} km dari posisi Anda',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onReportSelected(report);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Lihat Detail Laporan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userPoint = LatLng(widget.userLatitude, widget.userLongitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userPoint,
            initialZoom: 13.5,
            minZoom: 11.0, // PRD §8: Zoom dibatasi agar sejalan batas 10 km
            maxZoom: 18.0,
          ),
          children: [
            // Tile Layer OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.lapor_jalan',
            ),

            // Lingkaran Overlay Radius (PRD §8)
            CircleLayer<Object>(
              circles: <CircleMarker>[
                CircleMarker(
                  point: userPoint,
                  radius: widget.radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Marker Layer
            MarkerLayer(
              markers: [
                // Marker Posisi User
                Marker(
                  point: userPoint,
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

                // Marker Laporan-laporan Kerusakan Jalan
                ...widget.reports.map((report) {
                  final color = _severityColor(report.severity);
                  return Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showReportBottomSheet(context, report),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Tombol Recenter ke Posisi Pengguna
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter_map',
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            onPressed: () {
              _mapController.move(userPoint, 13.5);
            },
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}
