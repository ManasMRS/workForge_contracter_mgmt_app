import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'repository.dart';

/// Watches the device's connectivity and automatically pushes any
/// queued offline changes (creates/updates/deletes made while offline)
/// as soon as the connection comes back.
class ConnectivitySyncListener {
  final Repository repository;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  ConnectivitySyncListener(this.repository);

  void start() {
    // Try once immediately in case there's already pending work.
    repository.syncPending();

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) repository.syncPending();
    });
  }

  void stop() => _sub?.cancel();
}
