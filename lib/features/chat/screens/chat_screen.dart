import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/chat/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final text = _controller.text;
    _controller.clear();
    await ref.read(chatNotifierProvider(widget.requestId).notifier).send(
          senderId: user.id,
          senderName: user.firstName,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.requestId));
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hi to coordinate pickup.\nChat unlocks after the ride is confirmed.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == user?.id;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isMine
                              ? null
                              : Border.all(color: const Color(0xFFE8ECEB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoalMuted,
                                ),
                              ),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMine ? Colors.white : AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeFormat.format(message.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.charcoalMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
