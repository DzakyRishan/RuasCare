import 'package:flutter/material.dart';
import 'package:lapor_jalan/core/theme/app_colors.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

/// Badge chip penanda status laporan (PRD §7).
class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ReportStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ReportStatus.dilaporkan => (
          AppColors.statusDilaporkan,
          Icons.pending_actions_rounded,
        ),
      ReportStatus.diverifikasi => (
          AppColors.statusDiverifikasi,
          Icons.verified_rounded,
        ),
      ReportStatus.diperbaiki => (
          AppColors.statusDiperbaiki,
          Icons.check_circle_rounded,
        ),
      ReportStatus.ditolak => (
          AppColors.statusDitolak,
          Icons.cancel_rounded,
        ),
    };

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge penanda tingkat keparahan (PRD §6: Ringan, Sedang, Parah).
class ReportSeverityBadge extends StatelessWidget {
  const ReportSeverityBadge({
    super.key,
    required this.severity,
  });

  final ReportSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (severity) {
      ReportSeverity.ringan => (
          AppColors.severityRingan,
          Icons.info_outline_rounded,
        ),
      ReportSeverity.sedang => (
          AppColors.severitySedang,
          Icons.warning_amber_rounded,
        ),
      ReportSeverity.parah => (
          AppColors.severityParah,
          Icons.report_problem_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            severity.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
