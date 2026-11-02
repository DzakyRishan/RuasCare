import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/core/constants/app_constants.dart';
import 'package:lapor_jalan/core/router/app_routes.dart';
import 'package:lapor_jalan/features/auth/data/fake/fake_users.dart';
import 'package:lapor_jalan/features/auth/presentation/controllers/auth_controller.dart';

/// Layar Login pengguna (Warga dan Petugas).
///
/// Menyertakan disclaimer resmi pihak ketiga (PRD §8) dan shortcut akun demo
/// untuk memudahkan peninjau portofolio mencoba kedua peran (PRD §5).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoAccount(String email) {
    _emailController.text = email;
    _passwordController.text = FakeUsers.demoPassword;
    ref.read(authControllerProvider.notifier).clearErrors();
  }

  Future<void> _handleLogin() async {
    ref.read(authControllerProvider.notifier).clearErrors();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // Router refresh stream akan otomatis me-redirect ke halaman tujuan sesuai role.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final emailError = authState.fieldErrors['email']?.firstOrNull;
    final passwordError = authState.fieldErrors['password']?.firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Icon & Title
                    Icon(
                      Icons.traffic_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Laporkan jalan rusak di sekitarmu dengan cepat dan transparan',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Disclaimer Pihak Ketiga (PRD §8)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppConstants.officialDisclaimer,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Banner Error Umum jika ada
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !authState.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: emailError,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !authState.isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tombol Login
                    FilledButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Navigasi ke Register
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.go(AppRoutes.register),
                          child: const Text('Daftar Akun Warga'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 12),

                    // Bagian Akun Demo Portofolio (PRD §5)
                    Text(
                      'PILIH AKUN DEMO (PORTOFOLIO)',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_outline, size: 18),
                            label: const Text('Warga (Budi)'),
                            onPressed: authState.isLoading
                                ? null
                                : () => _fillDemoAccount(FakeUsers.budi.email),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.badge_outlined, size: 18),
                            label: const Text('Petugas (Rina)'),
                            onPressed: authState.isLoading
                                ? null
                                : () => _fillDemoAccount(FakeUsers.petugas.email),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
