import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

/// Baris laporan versi "database" di Fake repository.
///
/// Menyimpan [ownerId] dan [reporter] terpisah dari [report], sama seperti
/// backend menyimpan `user_id` tetapi tidak mengirimnya di respons publik.
class FakeReportRecord {
  FakeReportRecord({
    required this.ownerId,
    required this.reporter,
    required this.report,
  });

  final int ownerId;
  final ReportReporter reporter;

  /// Versi tersimpan: selalu tanpa [Report.reporter], [Report.isMine], dan
  /// [Report.distanceKm]. Field tersebut diisi per penampil saat dibaca.
  Report report;
}

/// Satu langkah perubahan status setelah laporan dibuat.
class _Step {
  const _Step(
    this.to,
    this.after, {
    this.note,
    this.rejectReason,
    this.changedByRole = UserRole.petugas,
  });

  final ReportStatus to;

  /// Selisih waktu dari saat laporan dibuat.
  final Duration after;
  final String? note;
  final RejectReason? rejectReason;
  final UserRole changedByRole;
}

/// Membangun 16 laporan mock di sekitar Jakarta Pusat.
///
/// Sebaran sengaja dibuat untuk menguji aturan PRD:
/// - 7 laporan dalam radius 5 km dari lokasi default (Monas).
/// - 5 laporan di antara 5 dan 10 km (muncul hanya jika radius diperbesar).
/// - 4 laporan di luar 10 km (tidak boleh muncul di daftar/peta warga),
///   salah satunya milik Budi sehingga tetap terlihat di "Laporan Saya".
/// - Semua status terwakili, termasuk laporan ditolak lalu diajukan ulang.
/// - Andi tidak punya laporan (empty state "Laporan Saya").
List<FakeReportRecord> buildFakeReportSeed({DateTime? now}) {
  final base = now ?? DateTime.now();
  var logId = 0;

  DateTime ago({int days = 0, int hours = 0}) =>
      base.subtract(Duration(days: days, hours: hours));

  FakeReportRecord record({
    required int id,
    required User owner,
    required String description,
    required ReportSeverity severity,
    required double latitude,
    required double longitude,
    required DateTime createdAt,
    List<_Step> steps = const [],
  }) {
    final history = <ReportStatusLog>[
      ReportStatusLog(
        id: ++logId,
        fromStatus: null,
        toStatus: ReportStatus.dilaporkan,
        changedByRole: UserRole.warga,
        createdAt: createdAt,
        note: 'Laporan dibuat.',
      ),
    ];
    var status = ReportStatus.dilaporkan;
    RejectReason? rejectReason;
    String? rejectNote;
    var updatedAt = createdAt;

    for (final step in steps) {
      final at = createdAt.add(step.after);
      history.add(
        ReportStatusLog(
          id: ++logId,
          fromStatus: status,
          toStatus: step.to,
          changedByRole: step.changedByRole,
          createdAt: at,
          note: step.note,
        ),
      );
      if (step.to == ReportStatus.ditolak) {
        rejectReason = step.rejectReason;
        rejectNote = step.note;
      } else {
        rejectReason = null;
        rejectNote = null;
      }
      status = step.to;
      updatedAt = at;
    }

    return FakeReportRecord(
      ownerId: owner.id,
      reporter: ReportReporter(
        id: owner.id,
        name: owner.name,
        email: owner.email,
      ),
      report: Report(
        id: id,
        description: description,
        severity: severity,
        status: status,
        latitude: latitude,
        longitude: longitude,
        photoUrls: [
          'https://picsum.photos/seed/lapor-jalan-$id-1/800/600',
          'https://picsum.photos/seed/lapor-jalan-$id-2/800/600',
          'https://picsum.photos/seed/lapor-jalan-$id-3/800/600',
        ],
        createdAt: createdAt,
        updatedAt: updatedAt,
        rejectReason: rejectReason,
        rejectNote: rejectNote,
        statusHistory: List.unmodifiable(history),
      ),
    );
  }

  return [
    // ---------------------------------------------------- dalam 5 km
    record(
      id: 1,
      owner: FakeUsers.budi,
      description: 'Lubang besar diameter sekitar 1 meter di lajur kiri Jl. '
          'Medan Merdeka Barat dekat halte TransJakarta. Pagi ini ada '
          'pengendara motor yang terjatuh.',
      severity: ReportSeverity.parah,
      latitude: -6.176700,
      longitude: 106.822200,
      createdAt: ago(hours: 2),
    ),
    record(
      id: 2,
      owner: FakeUsers.siti,
      description: 'Aspal amblas di depan gedung perkantoran Jl. Kebon Sirih, '
          'kedalaman kira-kira 10 cm. Mobil harus mengurangi kecepatan '
          'mendadak.',
      severity: ReportSeverity.sedang,
      latitude: -6.184900,
      longitude: 106.828500,
      createdAt: ago(days: 3),
      steps: const [
        _Step(
          ReportStatus.diverifikasi,
          Duration(hours: 20),
          note: 'Sudah dicek ke lapangan, masuk jadwal perbaikan minggu ini.',
        ),
      ],
    ),
    record(
      id: 3,
      owner: FakeUsers.siti,
      description: 'Beberapa lubang kecil berderet di Jl. Cikini Raya dekat '
          'stasiun, sering tergenang air setelah hujan.',
      severity: ReportSeverity.ringan,
      latitude: -6.191200,
      longitude: 106.839300,
      createdAt: ago(days: 12),
      steps: const [
        _Step(
          ReportStatus.diverifikasi,
          Duration(days: 1),
          note: 'Terverifikasi, diteruskan ke tim pemeliharaan.',
        ),
        _Step(
          ReportStatus.diperbaiki,
          Duration(days: 6),
          note: 'Tambal sulam selesai dikerjakan.',
        ),
      ],
    ),
    record(
      id: 4,
      owner: FakeUsers.budi,
      description: 'Jalan berlubang cukup dalam di Jl. Gunung Sahari arah '
          'Ancol, tepat sebelum lampu merah.',
      severity: ReportSeverity.parah,
      latitude: -6.155300,
      longitude: 106.837200,
      createdAt: ago(days: 5),
      steps: const [
        _Step(
          ReportStatus.ditolak,
          Duration(days: 1),
          rejectReason: RejectReason.duplikat,
          note: 'Titik yang sama sudah dilaporkan dan sedang diproses.',
        ),
      ],
    ),
    record(
      id: 5,
      owner: FakeUsers.siti,
      description: 'Aspal bergelombang dan retak memanjang sekitar 15 meter di '
          'Jl. Salemba Raya depan kampus. Berbahaya saat hujan karena '
          'tergenang.',
      severity: ReportSeverity.sedang,
      latitude: -6.195800,
      longitude: 106.850500,
      createdAt: ago(days: 1),
    ),
    record(
      id: 6,
      owner: FakeUsers.siti,
      description: 'Retakan kecil di dekat zebra cross Jl. M.H. Thamrin. Belum '
          'berlubang, tetapi lapisan aspal mulai mengelupas.',
      severity: ReportSeverity.ringan,
      latitude: -6.193000,
      longitude: 106.822900,
      createdAt: ago(hours: 6),
    ),
    record(
      id: 7,
      owner: FakeUsers.budi,
      description: 'Penutup saluran di Jl. Kramat Raya ambles sehingga '
          'membentuk cekungan di badan jalan.',
      severity: ReportSeverity.ringan,
      latitude: -6.186600,
      longitude: 106.844800,
      createdAt: ago(days: 20),
      steps: const [
        _Step(ReportStatus.diverifikasi, Duration(days: 2)),
        _Step(
          ReportStatus.diperbaiki,
          Duration(days: 9),
          note: 'Penutup saluran sudah diganti dan permukaan diratakan.',
        ),
      ],
    ),
    // ---------------------------------------------------- 5 sampai 10 km
    record(
      id: 8,
      owner: FakeUsers.siti,
      description: 'Lubang di Jl. Gatot Subroto dekat Semanggi, lajur cepat. '
          'Kendaraan sering menghindar mendadak sehingga rawan tabrakan.',
      severity: ReportSeverity.parah,
      latitude: -6.219600,
      longitude: 106.813700,
      createdAt: ago(days: 4),
    ),
    record(
      id: 9,
      owner: FakeUsers.budi,
      description: 'Permukaan jalan Jl. H.R. Rasuna Said rusak dan berkerikil '
          'di sekitar putaran balik, motor mudah tergelincir.',
      severity: ReportSeverity.sedang,
      latitude: -6.221200,
      longitude: 106.831800,
      createdAt: ago(days: 8),
      steps: const [
        _Step(
          ReportStatus.ditolak,
          Duration(days: 1),
          rejectReason: RejectReason.fotoTidakJelas,
          note: 'Foto buram, kerusakan tidak terlihat.',
        ),
        _Step(
          ReportStatus.dilaporkan,
          Duration(days: 2),
          note: 'Diajukan ulang oleh pelapor.',
          changedByRole: UserRole.warga,
        ),
      ],
    ),
    record(
      id: 10,
      owner: FakeUsers.siti,
      description: 'Jl. Pramuka arah Matraman banyak tambalan yang terkelupas '
          'kembali dan membentuk lubang baru.',
      severity: ReportSeverity.parah,
      latitude: -6.197600,
      longitude: 106.870500,
      createdAt: ago(days: 6),
      steps: const [
        _Step(
          ReportStatus.diverifikasi,
          Duration(days: 2),
          note: 'Masuk daftar prioritas perbaikan.',
        ),
      ],
    ),
    record(
      id: 11,
      owner: FakeUsers.siti,
      description: 'Jalan di Jl. Pemuda Rawamangun dibongkar dan dibiarkan '
          'terbuka tanpa rambu.',
      severity: ReportSeverity.sedang,
      latitude: -6.193200,
      longitude: 106.891500,
      createdAt: ago(days: 9),
      steps: const [
        _Step(
          ReportStatus.ditolak,
          Duration(days: 1),
          rejectReason: RejectReason.bukanJalanRusak,
          note: 'Lokasi merupakan galian utilitas resmi yang sedang '
              'dikerjakan.',
        ),
      ],
    ),
    record(
      id: 12,
      owner: FakeUsers.siti,
      description: 'Retak rambut di beberapa titik Jl. Pluit Raya, mulai '
          'melebar setelah musim hujan.',
      severity: ReportSeverity.ringan,
      latitude: -6.118500,
      longitude: 106.790500,
      createdAt: ago(days: 30),
      steps: const [
        _Step(ReportStatus.diverifikasi, Duration(days: 3)),
        _Step(
          ReportStatus.diperbaiki,
          Duration(days: 14),
          note: 'Pelapisan ulang aspal selesai.',
        ),
      ],
    ),
    // ---------------------------------------------------- di luar 10 km
    record(
      id: 13,
      owner: FakeUsers.siti,
      description: 'Lubang dalam di Jl. T.B. Simatupang dekat pintu tol, '
          'sudah dua kali menyebabkan ban mobil pecah.',
      severity: ReportSeverity.parah,
      latitude: -6.292200,
      longitude: 106.818700,
      createdAt: ago(days: 2),
    ),
    record(
      id: 14,
      owner: FakeUsers.budi,
      description: 'Jl. Ahmad Yani Bekasi depan pusat perbelanjaan '
          'bergelombang parah di lajur lambat.',
      severity: ReportSeverity.sedang,
      latitude: -6.246800,
      longitude: 106.991800,
      createdAt: ago(days: 7),
      steps: const [
        _Step(
          ReportStatus.diverifikasi,
          Duration(days: 3),
          note: 'Terverifikasi, koordinasi dengan pemerintah kota setempat.',
        ),
      ],
    ),
    record(
      id: 15,
      owner: FakeUsers.siti,
      description: 'Jl. Daan Mogot Tangerang dekat halte, aspal hancur sepanjang '
          'kurang lebih 30 meter.',
      severity: ReportSeverity.parah,
      latitude: -6.170200,
      longitude: 106.640500,
      createdAt: ago(days: 1, hours: 5),
    ),
    record(
      id: 16,
      owner: FakeUsers.siti,
      description: 'Jalan rusak di Jl. Raya Bogor Cibinong dekat pasar.',
      severity: ReportSeverity.sedang,
      latitude: -6.481800,
      longitude: 106.854500,
      createdAt: ago(days: 10),
      steps: const [
        _Step(
          ReportStatus.ditolak,
          Duration(days: 2),
          rejectReason: RejectReason.lokasiTidakSesuai,
          note: 'Titik GPS tidak sesuai dengan lokasi pada foto.',
        ),
      ],
    ),
  ];
}
