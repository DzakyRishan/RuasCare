# Keputusan Teknis (DECISIONS.md)

1. **Frontend Framework:** Flutter (Android saja) untuk target portofolio mobile.
2. **State Management:** Riverpod (`flutter_riverpod`) karena reaktif, aman, dan mudah diuji.
3. **Peta:** `flutter_map` dengan tile OpenStreetMap (gratis dan bebas kunci API berbayar untuk MVP).
4. **Arsitektur:** Feature-first / Clean Architecture (`lib/features/<fitur>/{data,domain,presentation}`).
5. **Data Layer:** Repository Pattern. Untuk fase awal / MVP frontend, menggunakan `FakeReportRepository` yang mengembalikan data mock realistis, sebelum dihubungkan ke backend Spring Boot.
6. **Backend:** Spring Boot 3.3 REST API + Spring Security JWT + PostgreSQL.
