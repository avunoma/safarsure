import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

final cloudSyncAvailableProvider = Provider<bool>((ref) {
  return ref.watch(cloudSyncServiceProvider).isAvailable;
});

class CloudSyncPoller extends StateNotifier<int> {
  CloudSyncPoller(this._ref) : super(0) {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  final Ref _ref;
  late final Timer _timer;

  Future<void> _poll() async {
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

class _CloudSyncHostState extends ConsumerState<CloudSyncHost> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user != null) {
      ref.watch(cloudSyncPollerProvider);
    }
    return widget.child;
  }
}
