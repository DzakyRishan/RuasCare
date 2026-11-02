import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/router/app_router.dart';
import 'package:lapor_jalan/core/theme/app_theme.dart';

/// Root widget aplikasi menggunakan [MaterialApp.router].
class LaporJalanApp extends ConsumerWidget {
  const LaporJalanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
