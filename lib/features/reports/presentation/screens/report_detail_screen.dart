import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/core/theme/app_colors.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_badges.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/status_history_timeline.dart';

/// Layar Detail Laporan Jalan Rusak (PRD §6, §7, §8, §11).
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  final int reportId;

  Color _severityColor(ReportSeverity severity) {
    return switch (severity) {
      ReportSeverity.ringan => AppColors.severityRingan,
      ReportSeverity.sedang => AppColors.severitySedang,
      ReportSeverity.parah => AppColors.severityParah,
    };
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _monthName(int m) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(reportDetailControllerProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Laporan #$reportId'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(reportDetailControllerProvider(reportId)),
          ),
        ],
      ),
      body: reportAsync.when(
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
                  Icons.error_outline_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat detail laporan',
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
                  onPressed: () => ref.invalidate(reportDetailControllerProvider(reportId)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (report) {
          final reportPoint = LatLng(report.latitude, report.longitude);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Foto Laporan Utama
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    report.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Foto tidak dapat dimuat',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. Banner Penolakan (PRD §7: jika status Ditolak)
                      if (report.isRejected) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.cancel_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Laporan Ditolak',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (report.rejectReason != null)
                                Text(
                                  'Alasan: ${report.rejectReason!.label}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (report.rejectNote != null &&
                                  report.rejectNote!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatan Petugas: "${report.rejectNote}"',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                              if (report.canOwnerResubmit) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onErrorContainer,
                                    side: BorderSide(
                                      color:
                                          theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  onPressed: () => context.go(
                                    AppRoutes.resubmitReportPath(report.id),
                                  ),
                                  icon: const Icon(Icons.replay_rounded, size: 18),
                                  label: const Text('Ajukan Ulang Laporan'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. Status, Keparahan, dan Jarak
                      Row(
                        children: [
                          ReportStatusChip(status: report.status),
                          const SizedBox(width: 8),
                          ReportSeverityBadge(severity: report.severity),
                          const Spacer(),
                          if (report.isMine)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Laporan Saya',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Waktu Pelaporan
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dilaporkan pada ${_formatDateTime(report.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Deskripsi Lengkap Kerusakan Jalan
                      Text(
                        'Deskripsi Kerusakan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          report.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Lokasi Peta (Mini Map)
                      Row(
                        children: [
                          Text(
                            'Titik Lokasi Kerusakan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: reportPoint,
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // Statis mini map
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.lapor_jalan',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: reportPoint,
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _severityColor(report.severity),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 6,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6. Identitas Pelapor (HANYA terlihat oleh petugas, PRD §3 & §17)
                      if (report.reporter != null) ...[
                        Text(
                          'Data Pelapor (Khusus Petugas)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.reporter!.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      report.reporter!.email,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 7. Riwayat Perubahan Status (PRD §7 & §12)
                      Text(
                        'Riwayat Tindak Lanjut',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatusHistoryTimeline(history: report.statusHistory),

                      // 8. Aksi Pemilik (PRD §7: jika status masih Dilaporkan)
                      if (report.canOwnerEditOrDelete) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.go(
                                  AppRoutes.editReportPath(report.id),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Ubah Laporan'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hapus Laporan?'),
                                      content: const Text(
                                        'Laporan yang dihapus tidak dapat dipulihkan kembali.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Batal'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    // TODO: panggil aksi delete report
                                    context.pop();
                                  }
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Hapus Laporan'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
