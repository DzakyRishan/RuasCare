import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/auth/data/auth_repository_provider.dart';
import 'package:lapor_jalan/features/auth/presentation/controllers/auth_controller.dart';

/// Beranda Warga: pintasan ke buat laporan, laporan saya, dan peta sekitar.
///
/// Warna mengikuti tema aplikasi (`AppTheme`, biru) supaya sama dengan layar lain.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cara Memakai RuasCare'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Tekan Buat Laporan, lalu isi lokasi jalan dan deskripsi.',
              ),
              const SizedBox(height: 8),
              const Text('2. Aktifkan GPS dan lampirkan 2-3 foto kerusakan.'),
              const SizedBox(height: 8),
              const Text(
                '3. Pantau status di Laporan Saya: Dilaporkan, Diverifikasi, '
                'lalu Diperbaiki.',
              ),
              const SizedBox(height: 8),
              const Text(
                '4. Jika laporan ditolak, baca alasannya lalu ajukan ulang '
                'dengan foto atau keterangan baru.',
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.officialDisclaimer,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & akun
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RUASCARE.',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Your Road, Our Responsibility.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'Akun',
                      icon: Icon(
                        Icons.person_outline,
                        color: scheme.onPrimaryContainer,
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          ref.read(authControllerProvider.notifier).logout();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Text(user?.name ?? 'Warga'),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18, color: scheme.error),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar',
                                style: TextStyle(color: scheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Banner lapor cepat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lapor Cepat!',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Temukan jalan rusak? Langsung buat laporan.',
                            style: TextStyle(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.onPrimary,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () => context.push(AppRoutes.createReport),
                      child: Icon(Icons.bolt, color: scheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Menu Utama',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    scheme,
                    'Buat Laporan',
                    'Formulir detail',
                    Icons.add_road,
                    () => context.push(AppRoutes.createReport),
                  ),
                  _buildMenuCard(
                    scheme,
                    'Laporan Saya',
                    'Cek status',
                    Icons.history,
                    () => context.push(AppRoutes.myReports),
                  ),
                  _buildMenuCard(
                    scheme,
                    'Peta Sekitar',
                    'Pantau jalan',
                    Icons.map_outlined,
                    () => context.push(AppRoutes.nearbyReports),
                  ),
                  _buildMenuCard(
                    scheme,
                    'Bantuan',
                    'Panduan app',
                    Icons.help_outline,
                    () => _showHelp(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    ColorScheme scheme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: scheme.primary, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
