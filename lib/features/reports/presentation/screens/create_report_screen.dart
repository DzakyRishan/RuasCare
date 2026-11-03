import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/features/reports/data/device_location_repository_provider.dart';
import 'package:lapor_jalan/features/reports/domain/device_location_repository.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';
import 'package:lapor_jalan/features/reports/domain/report_location.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/create_report_controller.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reporterNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ReportPhoto> _photos = [];
  final _imagePicker = ImagePicker();

  ReportSeverity _selectedSeverity = ReportSeverity.sedang;
  ReportLocation? _reportLocation;
  String? _locationError;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _reporterNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      final location = await ref
          .read(deviceLocationRepositoryProvider)
          .getCurrentLocation();
      if (!mounted) return;
      setState(() => _reportLocation = location);
    } on DeviceLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _reportLocation = null;
        _locationError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reportLocation = null;
        _locationError = 'Lokasi perangkat tidak dapat diambil. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto per laporan.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tambahkan Foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickPhoto(source);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final selectedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (selectedFile == null) return;

      final bytes = await selectedFile.readAsBytes();
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto masih lebih dari 5 MB. Pilih foto lain.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _photos.add(
          ReportPhoto(fileName: selectedFile.name, bytes: bytes),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto tidak dapat dipilih. Periksa izin kamera atau galeri.'),
        ),
      );
    }
  }

  Future<bool> _confirmLowAccuracy(ReportLocation location) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akurasi GPS Rendah'),
        content: Text(
          'Akurasi lokasi saat ini sekitar ±${location.accuracyMeters.round()} meter. '
          'Lokasi laporan mungkin kurang tepat. Tetap kirim laporan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Perbarui Lokasi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tetap Kirim'),
          ),
        ],
      ),
    );
    return shouldContinue ?? false;
  }

  Future<void> _submit() async {
    if (_photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal lampirkan 2 foto kerusakan.')),
      );
      return;
    }
    if (_isGettingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunggu lokasi GPS selesai diambil.')),
      );
      return;
    }

    final reportLocation = _reportLocation;
    if (reportLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationError ?? 'Ambil lokasi GPS sebelum mengirim laporan.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (reportLocation.hasLowAccuracy && !await _confirmLowAccuracy(reportLocation)) {
      return;
    }

    final success = await ref
        .read(createReportControllerProvider.notifier)
        .submitReport(
          latitude: reportLocation.latitude,
          longitude: reportLocation.longitude,
          description: _descriptionController.text.trim(),
          severity: _selectedSeverity,
          photos: _photos,
          reporterName: _reporterNameController.text.trim(),
          location: _locationController.text.trim(),
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim!')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan.')),
      );
    }
  }

  Widget _buildLocationCard(ThemeData theme) {
    final location = _reportLocation;
    final colorScheme = theme.colorScheme;

    if (_isGettingLocation) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Mengambil lokasi GPS perangkat…')),
          ],
        ),
      );
    }

    if (location == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_off_rounded, color: colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _locationError ?? 'Lokasi GPS belum tersedia.',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    }

    final accuracyColor = location.hasLowAccuracy
        ? colorScheme.tertiary
        : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: location.hasLowAccuracy
            ? colorScheme.tertiaryContainer
            : Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accuracyColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gps_fixed_rounded, color: accuracyColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.hasLowAccuracy
                      ? 'Lokasi diambil, tetapi akurasi rendah'
                      : 'Lokasi GPS berhasil diambil',
                  style: TextStyle(
                    color: accuracyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${location.latitude.toStringAsFixed(6)}, '
                  '${location.longitude.toStringAsFixed(6)}',
                ),
                Text('Akurasi sekitar ±${location.accuracyMeters.round()} meter'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);
    final theme = Theme.of(context);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _reporterNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelapor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama pelapor wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Nama Jalan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Contoh: Jl. Sudirman No. 10',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Lokasi atau nama jalan wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildLocationCard(theme),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _loadCurrentLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Perbarui Lokasi GPS'),
              ),
              const SizedBox(height: 16),
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
                onChanged: (value) => setState(() => _selectedSeverity = value!),
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
                  Text('${_photos.length}/3', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length + (_photos.length < 3 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return InkWell(
                        onTap: _showPhotoSourceSheet,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32),
                              SizedBox(height: 4),
                              Text('Tambah', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _photos[index].bytes,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => setState(() => _photos.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Laporan',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
