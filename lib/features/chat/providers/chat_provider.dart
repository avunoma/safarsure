import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/providers/cloud_sync_provider.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

final chatMessagesProvider =
    Provider.family<AsyncValue<List<ChatMessage>>, String>((ref, requestId) {
  ref.watch(cloudSyncPollerProvider);
  final repoAsync = ref.watch(appRepositoryProvider);
  return repoAsync.whenData(
    (repo) => repo.getMessagesForRequest(requestId),
  );
});

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<void>, String>(
        (ref, requestId) {
  return ChatNotifier(ref, requestId);
});

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  ChatNotifier(this._ref, this._requestId) : super(const AsyncValue.data(null)) {
    _pollTimer = Timer.periodic(AppConfig.cloudSyncInterval, (_) => _pull());
  }

  final Ref _ref;
  final String _requestId;
  late final Timer _pollTimer;

  Future<void> _pull() async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final request = repo.getRequestById(_requestId);
    if (request == null) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

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
      _ref.invalidate(chatMessagesProvider(_requestId));
      await _ref.read(tripsProvider.notifier).refresh();
      await _ref.read(requestsProvider.notifier).refresh();
    }
  }

  Future<void> send({
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final repo = await _ref.read(appRepositoryProvider.future);
      await repo.sendMessage(
        requestId: _requestId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );
      _ref.invalidate(chatMessagesProvider(_requestId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }
}
