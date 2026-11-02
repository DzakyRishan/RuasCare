/// Tingkat keparahan (PRD §6). [apiValue] sama dengan kolom `severity`.
enum ReportSeverity {
  ringan('ringan', 'Ringan'),
  sedang('sedang', 'Sedang'),
  parah('parah', 'Parah');

  const ReportSeverity(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReportSeverity fromApiValue(String value) {
    return ReportSeverity.values.firstWhere(
      (severity) => severity.apiValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Severity tidak dikenal'),
    );
  }
}

/// Status laporan beserta alur transisinya (PRD §7).
///
/// ```
/// Dilaporkan -> Diverifikasi -> Diperbaiki
/// Dilaporkan -> Ditolak -> (warga ajukan ulang) -> Dilaporkan
/// ```
enum ReportStatus {
  dilaporkan('dilaporkan', 'Dilaporkan'),
  diverifikasi('diverifikasi', 'Diverifikasi'),
  diperbaiki('diperbaiki', 'Diperbaiki'),
  ditolak('ditolak', 'Ditolak');

  const ReportStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Status tujuan yang boleh dipilih petugas dari status ini.
  ///
  /// Kembali ke [dilaporkan] dari [ditolak] bukan aksi petugas, melainkan
  /// pengajuan ulang oleh warga pemilik.
  Set<ReportStatus> get officerTransitions {
    return switch (this) {
      ReportStatus.dilaporkan => const {
          ReportStatus.diverifikasi,
          ReportStatus.ditolak,
        },
      ReportStatus.diverifikasi => const {ReportStatus.diperbaiki},
      ReportStatus.diperbaiki => const {},
      ReportStatus.ditolak => const {},
    };
  }

  bool canOfficerChangeTo(ReportStatus target) =>
      officerTransitions.contains(target);

  static ReportStatus fromApiValue(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Status tidak dikenal'),
    );
  }
}

/// Alasan penolakan yang bisa dipilih petugas (PRD §7).
enum RejectReason {
  duplikat('duplikat', 'Duplikat'),
  bukanJalanRusak('bukan_jalan_rusak', 'Bukan jalan rusak'),
  fotoTidakJelas('foto_tidak_jelas', 'Foto tidak jelas'),
  lokasiTidakSesuai('lokasi_tidak_sesuai', 'Lokasi tidak sesuai');

  const RejectReason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RejectReason fromApiValue(String value) {
    return RejectReason.values.firstWhere(
      (reason) => reason.apiValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Alasan tidak dikenal'),
    );
  }
}
