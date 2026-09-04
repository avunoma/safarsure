import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

final cloudSyncAvailableProvider = Provider<bool>((ref) {
  return ref.watch(cloudSyncServiceProvider).isAvailable;
});

class CloudSyncPoller extends StateNotifier<int> {
  CloudSyncPoller(this._ref) : super(0) {
    Future.microtask(_poll);
    _timer = Timer.periodic(AppConfig.cloudSyncInterval, (_) => _poll());
  }

  final Ref _ref;
  late final Timer _timer;
  bool _paused = false;

  void setPaused(bool paused) => _paused = paused;

  Future<void> _poll() async {
    if (_paused) return;

    final cloud = _ref.read(cloudSyncServiceProvider);
    if (!cloud.isAvailable) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final repo = await _ref.read(appRepositoryProvider.future);
      final driverTrips = repo
          .getTrips()
          .where((t) => t.driverId == user.id)
          .map((t) => t.id)
          .toList();

      final changed = await repo.syncFromCloud(
        driverTripIds: driverTrips,
        riderUserId: user.id,
      );

      if (changed) {
        state++;
        await _ref.read(tripsProvider.notifier).refresh();
        await _ref.read(requestsProvider.notifier).refresh();
      }
    } on Object {
      // Quota / transient Firestore REST errors should not break the UI.
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final cloudSyncPollerProvider =
    StateNotifierProvider<CloudSyncPoller, int>((ref) {
  return CloudSyncPoller(ref);
});

/// Starts background cloud polling while the user is logged in.
class CloudSyncHost extends ConsumerStatefulWidget {
  const CloudSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudSyncHost> createState() => _CloudSyncHostState();
}

class _CloudSyncHostState extends ConsumerState<CloudSyncHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden;
    ref.read(cloudSyncPollerProvider.notifier).setPaused(paused);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user != null) {
      ref.watch(cloudSyncPollerProvider);
    }
    return widget.child;
  }
}
