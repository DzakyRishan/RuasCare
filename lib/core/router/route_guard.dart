import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/auth/domain/user.dart';

/// Logika redirect murni (tanpa Flutter) agar mudah diuji.
///
/// Mengembalikan path tujuan redirect, atau null bila [location] boleh
/// diakses oleh [user].
///
/// Ini hanya pengalaman pengguna; otorisasi sebenarnya tetap di backend
/// (PRD §13).
String? resolveRedirect({required User? user, required String location}) {
  if (location == AppRoutes.root) {
    return user == null ? AppRoutes.login : AppRoutes.homeFor(user.role);
  }

  final onAuthRoute = AppRoutes.isAuthRoute(location);

  // Belum login (atau token kedaluwarsa, PRD §9) -> ke login.
  if (user == null) {
    return onAuthRoute ? null : AppRoutes.login;
  }

  final home = AppRoutes.homeFor(user.role);

  // Sudah login tapi membuka login/register -> ke beranda role.
  if (onAuthRoute) return home;

  final onOfficerRoute = AppRoutes.isOfficerRoute(location);

  // Warga tidak boleh membuka area petugas, dan sebaliknya.
  if (user.isWarga && onOfficerRoute) return home;
  if (user.isPetugas && !onOfficerRoute) return home;

  return null;
}
