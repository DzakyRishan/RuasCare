import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/resubmit_report_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_photo_strip.dart';

class ResubmitReportScreen extends ConsumerStatefulWidget {
  const ResubmitReportScreen({required this.reportId, super.key});

  final int reportId;

  @override
  ConsumerState<ResubmitReportScreen> createState() => _ResubmitReportScreenState();
}

class _ResubmitReportScreenState extends ConsumerState<ResubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  final List<ReportPhoto> _photos = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();

    if (_photos.isEmpty && description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sertakan foto baru atau keterangan baru untuk mengajukan ulang.')),
      );
      return;
    }

    if (_photos.isNotEmpty && _photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jika mengganti foto, minimal lampirkan 2 foto.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(resubmitReportControllerProvider.notifier).resubmitReport(
          reportId: widget.reportId,
          description: description.isNotEmpty ? description : null,
          photos: _photos,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil diajukan ulang!')),
      );
      ref.invalidate(reportDetailControllerProvider(widget.reportId));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengajukan ulang laporan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailControllerProvider(widget.reportId));
    final resubmitState = ref.watch(resubmitReportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Ulang Laporan')),
      body: reportAsync.when(
        data: (report) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (report.isRejected) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Ditolak: ${report.rejectReason?.label ?? "Tidak ada alasan"}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            ],
                          ),
                          if (report.rejectNote != null && report.rejectNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              report.rejectNote!,
                              style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Lampirkan foto baru atau tambahkan keterangan untuk mengajukan ulang laporan Anda.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Baru (opsional)',
                      hintText: 'Jelaskan perubahan atau tambahan informasi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Foto Baru (opsional, 2-3 foto)', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_photos.length}/3', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ReportPhotoStrip(
                    newPhotos: _photos,
                    onPhotoAdded: (photo) => setState(() => _photos.add(photo)),
                    onNewPhotoRemoved: (index) => setState(() => _photos.removeAt(index)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: resubmitState.isLoading ? null : _submit,
                    child: resubmitState.isLoading 
                        ? const CircularProgressIndicator() 
                        : const Text('Ajukan Ulang', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
