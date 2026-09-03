import 'package:safarsure/core/utils/privacy.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';

abstract class CloudSyncService {
  bool get isAvailable;

  Future<void> upsertRequest(RideRequest request, {required bool revealRider});

  Future<List<RideRequest>> fetchRequestsForTrip(String tripId);

  Future<RideRequest?> fetchRequestBySyncCode(String syncCode);

  Future<RideRequest?> fetchRequestById(String requestId);

  Future<void> sendMessage(ChatMessage message);

  Future<List<ChatMessage>> fetchMessages(String requestId);
}

RideRequest requestToCloud(
  RideRequest request, {
  required bool revealRider,
}) {
  return request.copyWith(
    riderName: revealRider
        ? revealedFirstName(request.riderName)
        : 'Rider',
  );
}

ChatMessage messageToCloud(ChatMessage message) {
  return ChatMessage(
    id: message.id,
    requestId: message.requestId,
    senderId: message.senderId,
    senderName: revealedFirstName(message.senderName),
    text: message.text,
    sentAt: message.sentAt,
  );
}

Map<String, dynamic> requestToMap(RideRequest request) => {
      'id': request.id,
      'tripId': request.tripId,
      'riderId': request.riderId,
      'riderName': request.riderName,
      'seats': request.seats,
      'note': request.note,
      'status': request.status.name,
      'pickupPoint': request.pickupPoint,
      'pickupTime': request.pickupTime?.toIso8601String(),
      'createdAt': request.createdAt?.toIso8601String(),
      'syncCode': request.syncCode,
    };

RideRequest requestFromMap(Map<String, dynamic> map) {
  return RideRequest(
    id: map['id'] as String,
    tripId: map['tripId'] as String,
    riderId: map['riderId'] as String,
    riderName: map['riderName'] as String,
    seats: map['seats'] as int,
    note: map['note'] as String? ?? '',
    status: RequestStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => RequestStatus.waiting,
    ),
    pickupPoint: map['pickupPoint'] as String?,
    pickupTime: map['pickupTime'] != null
        ? DateTime.parse(map['pickupTime'] as String)
        : null,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String)
        : null,
    syncCode: map['syncCode'] as String?,
  );
}

Map<String, dynamic> messageToMap(ChatMessage message) => {
      'id': message.id,
      'requestId': message.requestId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'sentAt': message.sentAt.toIso8601String(),
    };

ChatMessage messageFromMap(Map<String, dynamic> map) {
  return ChatMessage(
    id: map['id'] as String,
    requestId: map['requestId'] as String,
    senderId: map['senderId'] as String,
    senderName: map['senderName'] as String,
    text: map['text'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
  );
}
