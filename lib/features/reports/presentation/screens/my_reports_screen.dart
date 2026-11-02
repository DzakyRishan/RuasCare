import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/my_reports_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_card.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReportsAsync = ref.watch(myReportsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Saya'),
      ),
      body: myReportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Belum ada laporan yang Anda buat.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.createReport),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Laporan Baru'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(myReportsControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      ReportCard(
                        report: report,
                        onTap: () => context.push(AppRoutes.reportDetailPath(report.id)),
                      ),
                      if (report.status == ReportStatus.dilaporkan)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                context.push(AppRoutes.editReportPath(report.id));
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Laporan?'),
                                    content: const Text('Laporan yang dihapus tidak bisa dikembalikan.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(myReportsControllerProvider.notifier)
                                      .deleteReport(report.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Ubah'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (report.status == ReportStatus.ditolak)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.push(AppRoutes.resubmitReportPath(report.id)),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Ajukan Ulang'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(myReportsControllerProvider.notifier).refresh(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
