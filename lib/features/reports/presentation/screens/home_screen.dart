import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RUASCARE.',
                        style: TextStyle(
                          color: Color(0xFFD7FF00),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Road Safety Portal',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white),
                      onPressed: () => context.push('/profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Urgent Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7FF00),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lapor Cepat!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kirim foto kerusakan parah dalam 5 detik.',
                            style: TextStyle(color: Colors.black.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () => context.push('/quick-report'),
                      child: const Icon(Icons.bolt, color: Color(0xFFD7FF00)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Menu Utama',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Menu Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    context,
                    'Buat Laporan',
                    'Formulir detail',
                    Icons.add_road,
                    '/create-report',
                  ),
                  _buildMenuCard(
                    context,
                    'Laporan Saya',
                    'Cek status',
                    Icons.history,
                    '/my-reports',
                  ),
                  _buildMenuCard(
                    context,
                    'Peta Sekitar',
                    'Pantau jalan',
                    Icons.map_outlined,
                    '/nearby',
                  ),
                  _buildMenuCard(
                    context,
                    'Bantuan',
                    'Panduan app',
                    Icons.help_outline,
                    '/help',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: const Color(0xFFD7FF00), size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
