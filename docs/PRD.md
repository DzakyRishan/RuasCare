# PRD: Aplikasi Pelaporan Jalan Rusak

Versi 0.1 (draft) · 16 Oktober 2026 · Penulis: Jekyyy · Nama app: belum ditentukan

## 1. Ringkasan

Aplikasi mobile Android tempat warga melaporkan jalan rusak (foto, lokasi GPS, deskripsi, tingkat keparahan), dan petugas dinas menindaklanjuti dengan memverifikasi, menolak, atau menandai laporan sebagai sudah diperbaiki. Aplikasi berperan sebagai perantara pihak ketiga dan bukan kanal resmi pemerintah.

Project ini dibuat mandiri untuk portofolio, dengan target pengerjaan sekitar 2 minggu. Fitur AI (deteksi kerusakan jalan) ditambahkan paling akhir sebagai fase 2.

## 2. Problem Statement

Warga yang menemukan jalan rusak tidak punya cara mudah untuk melaporkannya dengan lokasi yang akurat, dan tidak tahu apakah laporannya ditindaklanjuti. Petugas kesulitan mengumpulkan laporan yang terstruktur beserta lokasi dan tingkat keparahannya.

## 3. Tujuan dan Kriteria Keberhasilan

Tujuan: menghasilkan app yang berfungsi dari ujung ke ujung (warga melapor, petugas menindaklanjuti) dan bisa didemokan, lengkap dengan APK, README, dan dokumentasi API.

Kriteria keberhasilan (definition of done MVP):

- Warga dapat register, login, dan logout.
- Warga dapat membuat laporan berisi foto, lokasi GPS, deskripsi, dan tingkat keparahan.
- Warga melihat daftar dan peta laporan di sekitarnya, dengan radius maksimal 10 km.
- Laporan di jarak lebih dari 10 km tidak muncul di daftar atau peta warga.
- Response API publik tidak memuat nama, email, atau ID pelapor.
- Petugas dapat melihat semua laporan, memfilter, dan mengubah status.
- Penolakan wajib disertai alasan dan alasan tampil ke pelapor.
- Setiap perubahan status tercatat di riwayat status.
- APK dapat diinstal dan dijalankan di perangkat Android sungguhan.

## 4. Non-Goals (tidak dikerjakan di MVP)

- Platform iOS.
- Integrasi ke sistem atau kanal resmi dinas.
- Model AI, PostGIS, notifikasi push, dan mode offline.
- Role admin tersendiri.
- Voting atau konfirmasi laporan oleh warga lain.
- Blur otomatis wajah dan plat nomor pada foto.
- Poles UI lanjutan seperti animasi dan tema.

## 5. Pengguna dan Peran

| Peran | Deskripsi | Hak akses utama |
|---|---|---|
| Warga | Pengguna umum yang melaporkan jalan rusak | Membuat laporan, melihat laporan di sekitar (maks 10 km), mengelola laporan sendiri |
| Petugas | Petugas dinas yang menindaklanjuti laporan | Melihat semua laporan tanpa batas radius, mengubah status, menolak dengan alasan |

Kedua peran adalah akun di dalam app yang sama. Layar yang tampil ditentukan oleh role. Untuk portofolio, akun petugas dibuat sebagai akun demo.

## 6. Fitur MVP dan User Stories

### Autentikasi

- Sebagai pengguna, saya dapat mendaftar dan login agar laporan terhubung ke akun saya.

### Warga

- Sebagai warga, saya dapat membuat laporan dengan foto, lokasi GPS, deskripsi, dan tingkat keparahan (ringan, sedang, parah).
- Sebagai warga, saya dapat melihat peta dan daftar laporan di sekitar saya.
- Sebagai warga, saya dapat melihat detail laporan beserta statusnya.
- Sebagai warga, saya dapat melihat layar "Laporan Saya", mengubah atau menghapus laporan sendiri selama statusnya masih Dilaporkan.
- Sebagai warga, saya dapat melihat alasan penolakan dan mengajukan ulang laporan yang ditolak dengan foto atau keterangan baru.

### Petugas

- Sebagai petugas, saya dapat melihat semua laporan dan memfilter berdasarkan status atau tingkat keparahan.
- Sebagai petugas, saya dapat mengubah status laporan menjadi Diverifikasi atau Diperbaiki.
- Sebagai petugas, saya dapat menolak laporan dengan alasan wajib.

## 7. Alur Status Laporan

```
Dilaporkan -> Diverifikasi -> Diperbaiki
Dilaporkan -> Ditolak (alasan wajib) -> warga mengajukan ulang -> Dilaporkan
```

Aturan:

- Alasan penolakan dipilih dari daftar (duplikat, bukan jalan rusak, foto tidak jelas, lokasi tidak sesuai) ditambah catatan singkat.
- Tombol tolak tidak aktif sebelum alasan diisi.
- Setiap perubahan status dicatat di tabel riwayat status: siapa, dari status apa ke status apa, kapan, dan catatannya.
- Warga hanya dapat mengubah atau menghapus laporan saat status Dilaporkan.

## 8. Visibilitas dan Privasi

- Semua laporan terbuka untuk umum, sedangkan nama pelapor disembunyikan.
- API publik hanya mengirim foto, lokasi, deskripsi, tingkat keparahan, status, dan waktu. Identitas pelapor tidak dikirim, dan aturan ini diterapkan di sisi backend, bukan hanya di tampilan.
- Radius: default 5 km dari lokasi warga saat app dibuka, maksimal 10 km. Batas 10 km dipaksakan di backend (parameter radius dipotong ke 10 km). Zoom peta dibatasi di Flutter agar sejalan.
- Radius adalah fitur relevansi dan performa, bukan pembatas keamanan, karena koordinat dikirim dari app.
- Laporan milik sendiri selalu terlihat lewat "Laporan Saya", berapa pun jaraknya. Petugas tidak terkena batas radius.
- Foto dapat memuat wajah atau plat nomor. Untuk MVP dicatat sebagai risiko dan ditulis dalam syarat ketentuan singkat.
- App ini bukan kanal resmi pemerintah, dan pernyataan itu ditampilkan di app.

## 9. Kasus Tepi

- Izin kamera atau lokasi ditolak: peta tampil di lokasi default, dan pembuatan laporan tidak bisa dilanjutkan tanpa GPS.
- GPS mati atau akurasi rendah: tampilkan peringatan sebelum kirim.
- Tidak ada internet atau upload gagal: tampilkan error yang jelas dan sediakan tombol coba lagi, jangan kehilangan isian form.
- Daftar kosong: tampilkan empty state.
- Foto terlalu besar: kompres di app dan batasi ukuran di server.
- Laporan ganda di titik yang sama: dibiarkan di MVP, dicatat sebagai pengembangan lanjutan.
- Token kedaluwarsa: arahkan kembali ke login.

## 10. Arsitektur dan Tech Stack

- Frontend: Flutter (Android saja).
- Backend: Spring Boot REST API, Spring Security (JWT), Spring Data JPA, dan PostgreSQL. Token di app disimpan dengan `flutter_secure_storage`.
- Database: PostgreSQL. Query radius memakai rumus jarak (Haversine) terlebih dahulu. PostGIS (ST_DWithin) opsional jika waktu cukup.
- AI (fase 2): Python (FastAPI) dan model deteksi, dipanggil dari Spring Boot atau dijalankan di perangkat.

Pola di Flutter: layar tidak memanggil data langsung, tetapi lewat repository layer (misalnya ReportRepository). Awalnya diisi FakeReportRepository berisi data mock yang realistis (termasuk error, daftar kosong, dan delay loading), lalu diganti versi yang memanggil API Spring Boot.

Urutan kerja: kontrak API, frontend dengan mock, backend, sambungkan keduanya, poles, AI.

## 11. Kontrak API (draft)

Semua response berformat JSON. Detail contoh request dan response dilengkapi di tahap kontrak API.

| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| POST | /api/auth/register | Publik | Daftar akun warga |
| POST | /api/auth/login | Publik | Login, mengembalikan token |
| POST | /api/auth/logout | Login | Logout sisi client (menghapus token) |
| GET | /api/auth/me | Login | Profil dan role pengguna |
| GET | /api/reports/nearby?latitude=&longitude=&radiusKm= | Publik | Daftar laporan di sekitar (radius dipotong ke 10 km) |
| GET | /api/reports/{id} | Login | Detail laporan |
| POST | /api/reports | Warga | Buat laporan (multipart: foto, lat, lng, deskripsi, severity) |
| PUT | /api/reports/{id} | Warga pemilik | Ubah laporan (hanya status Dilaporkan) |
| DELETE | /api/reports/{id} | Warga pemilik | Hapus laporan (hanya status Dilaporkan) |
| GET | /api/my-reports | Warga | Laporan milik sendiri |
| POST | /api/reports/{id}/resubmit | Warga pemilik | Ajukan ulang laporan yang ditolak |
| GET | /api/officer/reports?status=&severity= | Petugas | Semua laporan dengan filter |
| PUT | /api/reports/{id}/status | Petugas | Ubah status (alasan wajib jika Ditolak) |

## 12. Skema Database (draft)

- users: id, name, email, password, role (warga/petugas), timestamps.
- reports: id, user_id, description, severity (ringan/sedang/parah), status (dilaporkan/diverifikasi/diperbaiki/ditolak), latitude, longitude, photo_urls, reject_reason, reject_note, timestamps. Indeks pada kolom lokasi dan status.
- report_status_logs: id, report_id, changed_by (user_id), from_status, to_status, note, created_at.

## 13. Keamanan

- Validasi seluruh input di server, termasuk tipe dan ukuran file.
- Otorisasi berbasis role di setiap endpoint (cek di backend, bukan hanya di app).
- Pemilik laporan dicek sebelum ubah atau hapus.
- Rate limit pada endpoint login dan pembuatan laporan.
- Token disimpan di flutter_secure_storage. File .env masuk .gitignore dan tidak ada rahasia di repository.
- Logika sensitif tidak dipercayakan ke app.

## 14. Strategi AI (Fase 2, dikerjakan terakhir)

- Fine-tuning model deteksi kerusakan jalan (misalnya YOLOv8) di Colab atau Kaggle, dengan dataset publik seperti RDD2022 sebagai titik awal.
- Model dipasang lewat FastAPI yang dipanggil Spring Boot, atau langsung di perangkat dengan TFLite.
- Metrik evaluasi dan target akurasi ditentukan saat fase ini dimulai.
- Rencana cadangan: jika model belum cukup akurat, app tetap berfungsi penuh dengan pelaporan manual. AI adalah nilai tambah, bukan penentu keberhasilan MVP.

## 15. Timeline (target 14 hari)

| Hari | Pekerjaan |
|---|---|
| 1-2 | Finalisasi PRD, kontrak API, setup Flutter dan Spring Boot |
| 3-7 | Flutter dengan data mock: layar, navigasi, kamera, GPS, peta |
| 8-11 | Spring Boot API: auth, CRUD laporan, upload foto, status dan log |
| 12-14 | Sambungkan frontend dan backend, perbaiki bug, README, build APK |

Hari 12-14 berfungsi sebagai cadangan. Jika waktu mepet, selesaikan Flutter dengan mock terlebih dahulu sehingga hasilnya tetap dapat didemokan.

## 16. Risiko

- Hal baru yang belum pernah dicoba: kamera dan GPS di Flutter, izin Android, peta, dan deploy backend. Rencana: coba tiap hal lebih awal dalam prototipe kecil.
- Pengerjaan dibantu AI (vibecoding): kode yang tidak dipahami sulit diperbaiki. Rencana: kerja per fitur, tes dan commit setiap fitur berjalan, dan pahami alur besarnya.
- Scope membengkak. Rencana: patuhi daftar Non-Goals.
- Integrasi mepet di akhir. Rencana: kontrak API dan repository layer dibuat sejak awal.
- Privasi foto. Rencana: syarat ketentuan di MVP, blur otomatis di fase lanjutan.

## 17. Open Questions

- Nama aplikasi.
- State management Flutter (Riverpod atau Bloc). → **Diputuskan: Riverpod.**
- Penyedia peta (Google Maps atau OpenStreetMap). → **Diputuskan: flutter_map + OpenStreetMap.**
- Apakah petugas boleh melihat identitas pelapor (usulan: boleh).
- Tempat hosting backend dan cara membagikan APK untuk demo.
- Struktur repository (monorepo atau terpisah) dan format commit.

## 18. Fase Lanjutan

- Model AI deteksi kerusakan dan saran tingkat keparahan.
- PostGIS untuk query radius dan deteksi laporan ganda.
- Penanda "belum ditindak" untuk laporan yang lama tidak diproses, dan statistik penolakan per petugas.
- Role admin untuk meninjau penolakan.
- Notifikasi push, mode offline, dan blur otomatis wajah serta plat nomor.
- Integrasi ke kanal resmi dinas.
