import 'dart:async';

import 'package:flutter/foundation.dart';

/// Menjembatani [Stream] ke [Listenable] agar GoRouter mengevaluasi ulang
/// redirect setiap kali status login berubah.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
