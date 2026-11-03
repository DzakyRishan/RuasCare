import 'dart:typed_data';

/// Berkas foto yang sudah dipilih dan diperkecil di perangkat.
class ReportPhoto {
  const ReportPhoto({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}
