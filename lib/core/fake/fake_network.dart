import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/core/error/app_exception.dart';

/// Skenario yang bisa dipaksakan pada semua Fake repository untuk menguji
/// state loading, error, dan kosong di layar.
enum FakeScenario {
  /// Data normal dengan delay realistis.
  normal,

  /// Semua daftar dikembalikan kosong (uji empty state, PRD §9).
  emptyLists,

  /// Semua panggilan gagal karena jaringan (uji tombol coba lagi, PRD §9).
  networkError,

  /// Semua panggilan gagal dengan error server 5xx.
  serverError,

  /// Semua panggilan yang butuh login gagal karena token kedaluwarsa
  /// (uji redirect ke login, PRD §9).
  sessionExpired,
}

/// Konfigurasi perilaku Fake repository.
class FakeConfig {
  const FakeConfig({
    this.scenario = FakeScenario.normal,
    this.baseLatency = const Duration(milliseconds: 700),
    this.latencyJitter = const Duration(milliseconds: 600),
    this.randomFailureRate = 0.08,
  }) : assert(
          randomFailureRate >= 0 && randomFailureRate <= 1,
          'randomFailureRate harus di antara 0 dan 1',
        );

  final FakeScenario scenario;

  /// Delay minimum setiap panggilan.
  final Duration baseLatency;

  /// Tambahan delay acak 0..[latencyJitter] agar terasa seperti jaringan asli.
  final Duration latencyJitter;

  /// Peluang sebuah panggilan gagal dengan [NetworkException] walau
  /// skenarionya [FakeScenario.normal]. Set 0 untuk demo yang stabil.
  final double randomFailureRate;

  FakeConfig copyWith({
    FakeScenario? scenario,
    Duration? baseLatency,
    Duration? latencyJitter,
    double? randomFailureRate,
  }) {
    return FakeConfig(
      scenario: scenario ?? this.scenario,
      baseLatency: baseLatency ?? this.baseLatency,
      latencyJitter: latencyJitter ?? this.latencyJitter,
      randomFailureRate: randomFailureRate ?? this.randomFailureRate,
    );
  }
}

/// Konfigurasi aktif. Bisa diubah saat runtime (misalnya dari menu debug)
/// tanpa membuat ulang repository, karena repository membacanya per panggilan.
final fakeConfigProvider = StateProvider<FakeConfig>(
  (ref) => const FakeConfig(),
);

/// Mensimulasikan perilaku jaringan: delay, kegagalan acak, dan skenario
/// paksa. Dipanggil di awal setiap method Fake repository.
class FakeNetwork {
  FakeNetwork(this._readConfig, {math.Random? random})
      : _random = random ?? math.Random();

  final FakeConfig Function() _readConfig;
  final math.Random _random;

  /// True bila daftar harus dikembalikan kosong.
  bool get forceEmptyLists =>
      _readConfig().scenario == FakeScenario.emptyLists;

  /// Tunggu delay lalu lempar error sesuai skenario.
  ///
  /// [requiresAuth] false untuk endpoint publik (login/register) sehingga
  /// skenario [FakeScenario.sessionExpired] tidak berlaku.
  Future<void> simulate({bool requiresAuth = true}) async {
    final config = _readConfig();
    final jitterMs = config.latencyJitter.inMilliseconds;
    final extraMs = jitterMs > 0 ? _random.nextInt(jitterMs + 1) : 0;
    await Future<void>.delayed(
      config.baseLatency + Duration(milliseconds: extraMs),
    );

    switch (config.scenario) {
      case FakeScenario.networkError:
        throw const NetworkException();
      case FakeScenario.serverError:
        throw const ServerException();
      case FakeScenario.sessionExpired:
        if (requiresAuth) throw const UnauthorizedException();
      case FakeScenario.normal:
      case FakeScenario.emptyLists:
        break;
    }

    if (_random.nextDouble() < config.randomFailureRate) {
      throw const NetworkException();
    }
  }
}
