# RuasCare

> **Your Road, Our Responsibility.**

RuasCare adalah aplikasi pelaporan jalan rusak berbasis Flutter dan Spring Boot. Warga dapat membuat laporan kerusakan jalan dengan lokasi, tingkat keparahan, deskripsi, dan foto. Petugas dapat meninjau laporan, memverifikasi, menolak dengan alasan, atau menandai perbaikan selesai.

> RuasCare adalah proyek portofolio dan perantara pihak ketiga, bukan kanal resmi pemerintah.

## Fitur

- Autentikasi JWT untuk akun Warga dan Petugas.
- Pembuatan, pembaruan, dan penghapusan laporan oleh pemilik saat status masih **Dilaporkan**.
- Daftar laporan milik pengguna dan laporan sekitar dengan radius maksimal 10 km.
- Peta OpenStreetMap melalui `flutter_map`.
- Dashboard Petugas dengan filter status dan keparahan.
- Alur status: **Dilaporkan → Diverifikasi → Diperbaiki**.
- Penolakan dengan alasan wajib, kemudian pengajuan ulang oleh Warga.
- Riwayat setiap perubahan status.
- Identitas pelapor hanya tersedia di endpoint Petugas, tidak pada endpoint publik.

## Status Pengembangan

Fitur inti autentikasi, laporan, dashboard Petugas, dan API status telah tersedia. Fitur berikut masih dalam pengembangan sebelum rilis Android:

- GPS perangkat dan validasi akurasi lokasi.
- Pemilihan foto dari kamera/galeri, kompresi, upload multipart, dan penyimpanan file server.
- Foto bukti perbaikan dari Petugas.
- Pengujian widget dan integrasi Android yang stabil.

## Tech Stack

| Bagian | Teknologi |
|---|---|
| Mobile | Flutter / Dart, Android |
| State management | Riverpod |
| Routing | go_router dengan auth guard |
| HTTP client | Dio |
| Peta | flutter_map + OpenStreetMap |
| Backend | Spring Boot 3.3, Java 17, Spring Data JPA |
| Security | Spring Security, JWT, BCrypt |
| Database | PostgreSQL |

## Struktur Proyek

```text
.
├── android/                 # Konfigurasi Android Flutter
├── backend/                 # REST API Spring Boot
│   └── src/main/java/com/laporjalan/
│       ├── config/          # CORS dan Spring Security
│       ├── controller/      # Endpoint API
│       ├── dto/             # Request dan response
│       ├── model/           # Entity dan enum
│       ├── repository/      # JPA repository
│       ├── security/        # JWT filter dan utility
│       └── service/         # Aturan bisnis
├── docs/                    # PRD dan keputusan teknis
├── lib/                     # Flutter feature-first architecture
│   ├── core/
│   └── features/
│       ├── auth/
│       └── reports/
└── test/                    # Unit dan widget test
```

## Menjalankan Backend

**Prasyarat:** Java 17+, PostgreSQL, dan Maven atau IDE yang mendukung Maven.

1. Buat database PostgreSQL bernama `lapor_jalan_db`.
2. Buka `backend/.env.example` sebagai daftar variabel yang diperlukan. Jangan commit file `.env` atau password asli.
3. Atur environment variable di terminal, misalnya PowerShell:

```powershell
$env:DB_URL='jdbc:postgresql://localhost:5432/lapor_jalan_db'
$env:DB_USERNAME='postgres'
$env:DB_PASSWORD='password-postgresql-lokal'
$env:JWT_SECRET='secret-acak-minimal-32-karakter'
```

4. Jalankan dari folder `backend`:

```powershell
mvn spring-boot:run
```

API berjalan di `http://localhost:8080`.

## Menjalankan Flutter

**Prasyarat:** Flutter SDK 3.6+ dan perangkat Android atau emulator.

```powershell
flutter pub get
flutter run
```

Untuk Flutter Web lokal, base URL `http://localhost:8080` dapat dipakai. Untuk Android emulator, gunakan `http://10.0.2.2:8080`; untuk perangkat fisik, gunakan alamat IP LAN laptop.

## Keamanan Konfigurasi

- Password database dan JWT secret dibaca dari environment variable.
- File `.env`, Android `local.properties`, keystore, folder build, cache Gradle, dan output Maven dikecualikan oleh `.gitignore`.
- File `backend/.env.example` aman di-commit karena hanya berisi placeholder.
- Jangan memasukkan token JWT, password asli, API key, atau kredensial production ke source code maupun Postman collection.

## Dokumentasi

- [PRD](docs/PRD.md)
- [Keputusan Teknis](docs/DECISIONS.md)
- [Koleksi Postman](backend/Lapor_Jalan_API.postman_collection.json)

## Checklist MVP

### Autentikasi
- [x] Pengguna dapat mendaftar dan login agar laporan terhubung ke akun.

### Warga
- [ ] Warga dapat membuat laporan dengan foto asli, lokasi GPS, deskripsi, dan tingkat keparahan.
- [x] Warga dapat melihat peta dan daftar laporan di sekitar (maksimal 10 km).
- [x] Warga dapat melihat detail laporan beserta statusnya.
- [ ] Warga dapat mengubah atau menghapus laporan sendiri selama statusnya masih Dilaporkan.
- [x] Warga dapat melihat alasan penolakan dan mengajukan ulang laporan yang ditolak.

### Petugas
- [x] Petugas dapat melihat semua laporan dan memfilter berdasarkan status atau tingkat keparahan.
- [x] Petugas dapat mengubah status laporan menjadi Diverifikasi atau Diperbaiki.
- [x] Petugas dapat menolak laporan dengan alasan wajib.
