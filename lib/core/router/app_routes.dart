import 'package:lapor_jalan/features/auth/domain/user.dart';

/// Daftar path dan nama route. Layar memakai helper di sini, bukan string
/// literal, agar perubahan path cukup di satu tempat.
abstract final class AppRoutes {
  /// Root URL browser. Selalu dialihkan oleh auth guard.
  static const String root = '/';

  // Auth (publik).
  static const String login = '/login';
  static const String register = '/register';

  // Warga.
  static const String nearbyReports = '/reports';
  static const String createReport = '/reports/new';
  static const String reportDetail = '/reports/:id';
  static const String myReports = '/my-reports';
  static const String editReport = '/my-reports/:id/edit';
  static const String resubmitReport = '/my-reports/:id/resubmit';

  // Petugas.
  static const String officerPrefix = '/officer';
  static const String officerReports = '/officer/reports';
  static const String officerReportDetail = '/officer/reports/:id';

  /// Nama route untuk `context.goNamed`.
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String nearbyReportsName = 'nearby-reports';
  static const String createReportName = 'create-report';
  static const String reportDetailName = 'report-detail';
  static const String myReportsName = 'my-reports';
  static const String editReportName = 'edit-report';
  static const String resubmitReportName = 'resubmit-report';
  static const String officerReportsName = 'officer-reports';
  static const String officerReportDetailName = 'officer-report-detail';

  /// Nama path parameter id laporan.
  static const String idParam = 'id';

  static String reportDetailPath(int id) => '/reports/$id';
  static String editReportPath(int id) => '/my-reports/$id/edit';
  static String resubmitReportPath(int id) => '/my-reports/$id/resubmit';
  static String officerReportDetailPath(int id) => '/officer/reports/$id';

  /// Beranda sesuai role (PRD §5: layar ditentukan oleh role).
  static String homeFor(UserRole role) {
    return switch (role) {
      UserRole.warga => nearbyReports,
      UserRole.petugas => officerReports,
    };
  }

  static bool isAuthRoute(String location) =>
      location == login || location == register;

  static bool isOfficerRoute(String location) =>
      location == officerPrefix || location.startsWith('$officerPrefix/');
}
