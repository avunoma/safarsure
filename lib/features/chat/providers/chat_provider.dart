import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/repositories/app_repository.dart';

final chatMessagesProvider =
    Provider.family<AsyncValue<List<ChatMessage>>, String>((ref, requestId) {
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
  ChatNotifier(this._ref, this._requestId) : super(const AsyncValue.data(null));

  final Ref _ref;
  final String _requestId;

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
}
