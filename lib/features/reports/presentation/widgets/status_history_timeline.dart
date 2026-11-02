import 'package:flutter/material.dart';
import 'package:lapor_jalan/core/theme/app_colors.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

/// Widget timeline vertikal untuk menampilkan riwayat perubahan status (PRD §7 & §12).
class StatusHistoryTimeline extends StatelessWidget {
  const StatusHistoryTimeline({
    super.key,
    required this.history,
  });

  final List<ReportStatusLog> history;

  Color _statusColor(ReportStatus status) {
    return switch (status) {
      ReportStatus.dilaporkan => AppColors.statusDilaporkan,
      ReportStatus.diverifikasi => AppColors.statusDiverifikasi,
      ReportStatus.diperbaiki => AppColors.statusDiperbaiki,
      ReportStatus.ditolak => AppColors.statusDitolak,
    };
  }

  IconData _statusIcon(ReportStatus status) {
    return switch (status) {
      ReportStatus.dilaporkan => Icons.add_circle_outline_rounded,
      ReportStatus.diverifikasi => Icons.verified_rounded,
      ReportStatus.diperbaiki => Icons.check_circle_rounded,
      ReportStatus.ditolak => Icons.cancel_rounded,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada riwayat status.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final log = history[index];
        final isLast = index == history.length - 1;
        final color = _statusColor(log.toStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Indikator & Garis Penghubung
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      _statusIcon(log.toStatus),
                      size: 14,
                      color: color,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Detail Log
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            log.fromStatus == null
                                ? 'Laporan Dibuat'
                                : 'Status: ${log.toStatus.label}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.changedByRole.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(log.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (log.note != null && log.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            log.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
