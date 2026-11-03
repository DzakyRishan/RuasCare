import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapor_jalan/features/reports/domain/report_photo.dart';

/// Deretan foto laporan dengan tombol tambah (Kamera/Galeri) dan hapus.
///
/// Dipakai oleh layar Edit, Ajukan Ulang, dan dialog bukti perbaikan Petugas.
/// Widget ini tidak menyimpan state foto: pemilik state yang mengubah daftar
/// lewat callback.
class ReportPhotoStrip extends StatelessWidget {
  const ReportPhotoStrip({
    super.key,
    required this.newPhotos,
    required this.onPhotoAdded,
    required this.onNewPhotoRemoved,
    this.existingUrls = const [],
    this.onExistingRemoved,
    this.maxPhotos = 3,
  });

  /// Foto lama dari server (tampil lewat jaringan).
  final List<String> existingUrls;

  /// Foto baru yang sudah dipilih dari Kamera/Galeri.
  final List<ReportPhoto> newPhotos;

  final int maxPhotos;
  final ValueChanged<ReportPhoto> onPhotoAdded;
  final ValueChanged<int> onNewPhotoRemoved;
  final ValueChanged<int>? onExistingRemoved;

  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  int get _total => existingUrls.length + newPhotos.length;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    if (_total >= maxPhotos) {
      _showMessage(context, 'Maksimal $maxPhotos foto.');
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

    if (source == null || !context.mounted) return;
    await _pick(context, source);
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        _showMessage(context, 'Foto masih lebih dari 5 MB. Pilih foto lain.');
        return;
      }
      onPhotoAdded(ReportPhoto(fileName: file.name, bytes: bytes));
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Foto tidak dapat dipilih. Periksa izin kamera atau galeri.',
      );
    }
  }

  Widget _removeButton(VoidCallback onTap) {
    return Positioned(
      top: 4,
      right: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _thumbnail({required Widget image, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 100, height: 100, child: image),
          ),
          _removeButton(onRemove),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAddButton = _total < maxPhotos;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < existingUrls.length; i++)
            _thumbnail(
              image: Image.network(
                existingUrls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
              ),
              onRemove: () => onExistingRemoved?.call(i),
            ),
          for (var i = 0; i < newPhotos.length; i++)
            _thumbnail(
              image: Image.memory(newPhotos[i].bytes, fit: BoxFit.cover),
              onRemove: () => onNewPhotoRemoved(i),
            ),
          if (showAddButton)
            InkWell(
              onTap: () => _showSourceSheet(context),
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
            ),
        ],
      ),
    );
  }
}
