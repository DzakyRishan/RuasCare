import 'package:flutter/material.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_badges.dart';

/// Card item laporan untuk tampilan daftar warga.
///
/// Menyajikan foto, status, severity, deskripsi singkat, jarak (PRD §8),
/// dan waktu laporan tanpa menampilkan identitas pelapor (PRD §3).
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  final Report report;
  final VoidCallback onTap;

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m <= 1 ? 'Baru saja' : '$m menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} hari lalu';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Foto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Image.network(
                    report.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.outline,
                          size: 32,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Detail Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Severity Badges
                    Row(
                      children: [
                        ReportSeverityBadge(severity: report.severity),
                        const SizedBox(width: 6),
                        ReportStatusChip(status: report.status, compact: true),
                        const Spacer(),
                        if (report.distanceKm != null)
                          Text(
                            '${report.distanceKm!.toStringAsFixed(1)} km',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Deskripsi
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Waktu Laporan & Penanda Laporan Saya
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatRelativeTime(report.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (report.isMine) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Laporan Saya',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
