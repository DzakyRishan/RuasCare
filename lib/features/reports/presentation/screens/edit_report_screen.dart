import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/edit_report_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:lapor_jalan/features/reports/presentation/widgets/report_photo_strip.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  const EditReportScreen({required this.reportId, super.key});

  final int reportId;

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  ReportSeverity? _selectedSeverity;

  /// Foto lama dari server yang masih dipertahankan.
  List<String> _existingUrls = [];

  /// Foto lama saat layar dibuka, untuk mendeteksi apakah foto berubah.
  List<String> _originalUrls = [];

  /// Foto baru dari Kamera/Galeri.
  final List<ReportPhoto> _newPhotos = [];
  bool _isInitialized = false;

  int get _photoCount => _existingUrls.length + _newPhotos.length;

  bool get _photosChanged =>
      _newPhotos.isNotEmpty || _existingUrls.length != _originalUrls.length;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_photoCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal lampirkan 2 foto kerusakan.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(editReportControllerProvider.notifier).updateReport(
          reportId: widget.reportId,
          description: _descriptionController.text.trim(),
          severity: _selectedSeverity,
          keepPhotoUrls: _photosChanged ? _existingUrls : null,
          newPhotos: _newPhotos,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil diperbarui!')),
      );
      ref.invalidate(reportDetailControllerProvider(widget.reportId));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perubahan atau gagal memperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailControllerProvider(widget.reportId));
    final editState = ref.watch(editReportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Laporan')),
      body: reportAsync.when(
        data: (report) {
          if (!_isInitialized) {
            _descriptionController.text = report.description;
            _selectedSeverity = report.severity;
            _existingUrls = List.of(report.photoUrls);
            _originalUrls = List.of(report.photoUrls);
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tingkat Keparahan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReportSeverity>(
                    initialValue: _selectedSeverity,
                    items: ReportSeverity.values
                        .map(
                          (severity) => DropdownMenuItem(
                            value: severity,
                            child: Text(severity.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSeverity = value),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Kerusakan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Deskripsi kerusakan wajib diisi.'
                        : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Foto Kerusakan (2-3 foto)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_photoCount/3',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ReportPhotoStrip(
                    existingUrls: _existingUrls,
                    newPhotos: _newPhotos,
                    onPhotoAdded: (photo) => setState(() => _newPhotos.add(photo)),
                    onNewPhotoRemoved: (index) =>
                        setState(() => _newPhotos.removeAt(index)),
                    onExistingRemoved: (index) =>
                        setState(() => _existingUrls.removeAt(index)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: editState.isLoading ? null : _submit,
                    child: editState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
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
