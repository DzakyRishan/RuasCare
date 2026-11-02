import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/core/router/go_router_refresh_stream.dart';
import 'package:lapor_jalan/core/router/route_guard.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/presentation/screens/login_screen.dart';
import 'package:lapor_jalan/features/auth/presentation/screens/register_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/create_report_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/edit_report_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/my_reports_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/nearby_reports_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/officer_dashboard_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:lapor_jalan/features/reports/presentation/screens/resubmit_report_screen.dart';

/// Provider konfigurasi [GoRouter].
///
/// Menggunakan `GoRouterRefreshStream` pada stream auth repository agar setiap
/// transisi login/logout/sesi kedaluwarsa memicu evaluasi redirect otomatis.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshListenable = GoRouterRefreshStream(authRepository.authStateChanges());
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      return resolveRedirect(
        user: authRepository.currentUser,
        location: state.matchedLocation,
      );
    },
    routes: [
      // Root harus terdaftar agar URL browser `/` dapat diproses auth guard.
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),

      // Auth (Publik)
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Warga
      GoRoute(
        path: AppRoutes.nearbyReports,
        name: AppRoutes.nearbyReportsName,
        builder: (context, state) => const NearbyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createReport,
        name: AppRoutes.createReportName,
        builder: (context, state) => const CreateReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportDetail,
        name: AppRoutes.reportDetailName,
        builder: (context, state) {
          final idStr = state.pathParameters[AppRoutes.idParam] ?? '';
          final id = int.tryParse(idStr) ?? 0;
          return ReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.myReports,
        name: AppRoutes.myReportsName,
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editReport,
        name: AppRoutes.editReportName,
        builder: (context, state) {
          final idStr = state.pathParameters[AppRoutes.idParam] ?? '';
          final id = int.tryParse(idStr) ?? 0;
          return EditReportScreen(reportId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.resubmitReport,
        name: AppRoutes.resubmitReportName,
        builder: (context, state) {
          final idStr = state.pathParameters[AppRoutes.idParam] ?? '';
          final id = int.tryParse(idStr) ?? 0;
          return ResubmitReportScreen(reportId: id);
        },
      ),

      // Petugas
      GoRoute(
        path: AppRoutes.officerReports,
        name: AppRoutes.officerReportsName,
        builder: (context, state) => const OfficerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.officerReportDetail,
        name: AppRoutes.officerReportDetailName,
        builder: (context, state) {
          final idString = state.pathParameters[AppRoutes.idParam] ?? '';
          final reportId = int.tryParse(idString) ?? 0;
          return ReportDetailScreen(reportId: reportId);
        },
      ),
    ],
  );
});
