import 'package:flutter/material.dart';

/// Palet warna aplikasi.
///
/// Warna tingkat keparahan dan status dipusatkan di sini agar badge, marker
/// peta, dan filter memakai warna yang sama di semua layar.
abstract final class AppColors {
  /// Warna dasar: Civic Trust Blue (elegan, terpercaya, modern layaknya JAKI/LAPOR).
  static const Color seed = Color(0xFF1A56DB);
  static const Color primary = Color(0xFF1A56DB);
  static const Color skyAccent = Color(0xFF0284C7);

  // Tingkat keparahan (PRD §6: ringan, sedang, parah).
  static const Color severityRingan = Color(0xFF2E7D32);
  static const Color severitySedang = Color(0xFFF9A825);
  static const Color severityParah = Color(0xFFC62828);

  // Status laporan (PRD §7).
  static const Color statusDilaporkan = Color(0xFF1565C0);
  static const Color statusDiverifikasi = Color(0xFF6A1B9A);
  static const Color statusDiperbaiki = Color(0xFF2E7D32);
  static const Color statusDitolak = Color(0xFF616161);
}
