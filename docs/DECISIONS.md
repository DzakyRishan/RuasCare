# Keputusan Teknis (DECISIONS.md)

1. **Frontend Framework:** Flutter (Android saja) untuk target portofolio mobile.
2. **State Management:** Riverpod (`flutter_riverpod`) karena reaktif, aman, dan mudah diuji.
3. **Peta:** `flutter_map` dengan tile OpenStreetMap (gratis dan bebas kunci API berbayar untuk MVP).
4. **Arsitektur:** Feature-first / Clean Architecture (`lib/features/<fitur>/{data,domain,presentation}`).
5. **Data Layer:** Repository Pattern. Untuk fase awal / MVP frontend, menggunakan `FakeReportRepository` yang mengembalikan data mock realistis, sebelum dihubungkan ke backend Spring Boot.
6. **Backend:** Spring Boot 3.3 REST API + Spring Security JWT + PostgreSQL.
7. **GPS Form:** Lokasi diambil sebelum laporan dikirim. Form menampilkan koordinat dan akurasi, menyediakan tombol perbarui lokasi, serta meminta konfirmasi bila akurasi lebih dari 100 meter.
8. **Upload Foto:** Form Buat Laporan membuka pilihan Kamera atau Galeri untuk setiap foto. Gambar diperkecil oleh Image Picker sebelum upload multipart; backend menerima PNG/JPEG/WEBP, maksimal 5 MB per foto, menggunakan nama UUID, dan menyimpan file di folder upload yang tidak di-commit.
9. **Bukti Perbaikan:** Status Diperbaiki hanya bisa dicapai lewat `POST /api/reports/{id}/fix` dengan 1-3 foto bukti. Endpoint status JSON menolak `DIPERBAIKI`, jadi Petugas tidak bisa menandai selesai tanpa foto. Role juga dicek di level URL (`SecurityConfig`) agar warga ditolak 403 sebelum body dibaca.
10. **Beranda Warga:** `/home` (`HomeScreen`) menjadi beranda Warga. Profil menjadi menu nama + Keluar, dan Bantuan berupa dialog panduan karena belum ada halaman terpisah.