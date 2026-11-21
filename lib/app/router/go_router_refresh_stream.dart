import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a stream to go_router's refreshListenable. Owns and cancels its
/// subscription on dispose (no leaks).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
