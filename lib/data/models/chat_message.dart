class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String? ?? 'User',
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
