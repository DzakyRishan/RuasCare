import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/officer_dashboard_controller.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_photo_strip.dart';

class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  ReportStatus? _selectedStatus;
  ReportSeverity? _selectedSeverity;

  void _showVerifyDialog(int reportId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Laporan'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan Petugas (opsional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(officerDashboardControllerProvider.notifier).updateStatus(
                reportId: reportId,
                newStatus: ReportStatus.diverifikasi,
                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(int reportId) {
    final noteController = TextEditingController();
    RejectReason? selectedReason = RejectReason.fotoTidakJelas;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Tolak Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Alasan Penolakan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<RejectReason>(
                initialValue: selectedReason,
                items: RejectReason.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.label),
                )).toList(),
                onChanged: (val) => setStateDialog(() => selectedReason = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Penolakan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                if (selectedReason == null) return;
                ref.read(officerDashboardControllerProvider.notifier).updateStatus(
                  reportId: reportId,
                  newStatus: ReportStatus.ditolak,
                  rejectReason: selectedReason,
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Tolak'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFixedDialog(int reportId) {
    final noteController = TextEditingController();
    final repairPhotos = <ReportPhoto>[];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Tandai Selesai / Diperbaiki'),
          // Lebar tetap: AlertDialog menghitung lebar intrinsik isinya, dan
          // ListView di ReportPhotoStrip tidak mendukung itu.
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Foto bukti perbaikan (1-3 foto, wajib)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ReportPhotoStrip(
                  newPhotos: repairPhotos,
                  onPhotoAdded: (photo) =>
                      setStateDialog(() => repairPhotos.add(photo)),
                  onNewPhotoRemoved: (index) =>
                      setStateDialog(() => repairPhotos.removeAt(index)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Perbaikan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              // Tombol aktif hanya setelah ada foto bukti (PRD: foto perbaikan).
              onPressed: repairPhotos.isEmpty
                  ? null
                  : () {
                      ref.read(officerDashboardControllerProvider.notifier).updateStatus(
                            reportId: reportId,
                            newStatus: ReportStatus.diperbaiki,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                            repairPhotos: List.of(repairPhotos),
                          );
                      Navigator.pop(dialogContext);
                    },
              child: const Text('Tandai Diperbaiki'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusActionDialog(Report report) {
    final isReported = report.status.label == ReportStatus.dilaporkan.label;
    final isVerified = report.status.label == ReportStatus.diverifikasi.label;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Status Laporan'),
        content: Text('Status saat ini: ${report.status.label}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          if (isReported) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showRejectDialog(report.id);
              },
              child: const Text('Tolak'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showVerifyDialog(report.id);
              },
              child: const Text('Verifikasi'),
            ),
          ],
          if (isVerified)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showFixedDialog(report.id);
              },
              child: const Text('Tandai Diperbaiki'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(officerDashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(officerDashboardControllerProvider.notifier).loadReports(
              status: _selectedStatus,
              severity: _selectedSeverity,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportStatus?>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Status')),
                      ...ReportStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      ref.read(officerDashboardControllerProvider.notifier).loadReports(
                        status: val,
                        severity: _selectedSeverity,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ReportSeverity?>(
                    initialValue: _selectedSeverity,
                    decoration: const InputDecoration(labelText: 'Keparahan', isDense: true, border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Keparahan')),
                      ...ReportSeverity.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSeverity = val);
                      ref.read(officerDashboardControllerProvider.notifier).loadReports(
                        status: _selectedStatus,
                        severity: val,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Reports List
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(child: Text('Tidak ada laporan.'));
                }
                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${report.id} - ${report.severity.label}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ActionChip(
                                  tooltip: 'Ubah status laporan',
                                  avatar: const Icon(
                                    Icons.sync_alt_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    report.status.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _getStatusColor(report.status),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _showStatusActionDialog(report),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pelapor: ${report.reporter?.name ?? "Warga"}',
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(report.description),
                            const SizedBox(height: 12),
                            if (report.photoUrls.isNotEmpty)
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: report.photoUrls.length,
                                  itemBuilder: (context, pIndex) => Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        report.photoUrls[pIndex],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Aksi selalu tampak. Opsi di dialog disesuaikan
                            // dengan status laporan saat ini.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () => context.push(
                                    AppRoutes.officerReportDetailPath(report.id),
                                  ),
                                  child: const Text('Detail'),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.dilaporkan:
        return Colors.amber.shade200;
      case ReportStatus.diverifikasi:
        return Colors.blue.shade200;
      case ReportStatus.diperbaiki:
        return Colors.green.shade200;
      case ReportStatus.ditolak:
        return Colors.red.shade200;
    }
  }
}
