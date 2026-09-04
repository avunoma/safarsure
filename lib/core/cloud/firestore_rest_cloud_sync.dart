import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/firestore_rest_client.dart';
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';

class FirestoreRestCloudSync implements CloudSyncService {
  FirestoreRestCloudSync({FirestoreRestClient? client})
      : _client = client ??
            FirestoreRestClient(
              projectId: AppConfig.demoFirebaseProjectId,
              apiKey: AppConfig.demoFirebaseApiKey,
            );

  final FirestoreRestClient _client;

  static const _requests = 'ride_requests';
  static const _trips = 'trips';

  @override
  bool get isAvailable => AppConfig.hasDemoCloudRest;

  @override
  Future<void> upsertTrip(Trip trip) async {
    if (!isAvailable) return;
    await _client.setDocument('$_trips/${trip.id}', {
      'tripJson': tripToJsonField(trip),
    });
  }

  @override
  Future<List<Trip>> fetchTrips() async {
    if (!isAvailable) return [];
    final docs = await _client.listCollection(_trips);
    return docs
        .map((doc) => tripFromJsonField(doc['tripJson'] as String?))
        .whereType<Trip>()
        .toList();
  }

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    if (!isAvailable) return;
    final cloud = requestToCloud(request, revealRider: revealRider);
    final data = requestToMap(cloud);
    await _client.setDocument('$_requests/${request.id}', data);
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async {
    if (!isAvailable) return [];
    final docs = await _client.queryCollectionEqual(
      collectionId: _requests,
      fieldPath: 'tripId',
      equalTo: tripId,
    );
    return docs.map(requestFromMap).toList();
  }

  @override
  Future<List<RideRequest>> fetchRequestsForRider(String riderId) async {
    if (!isAvailable) return [];
    final docs = await _client.queryCollectionEqual(
      collectionId: _requests,
      fieldPath: 'riderId',
      equalTo: riderId,
    );
    return docs.map(requestFromMap).toList();
  }

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async {
    if (!isAvailable) return null;
    final doc = await _client.getDocument('$_requests/$requestId');
    if (doc == null) return null;
    return requestFromMap(doc);
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    if (!isAvailable) return;
    final cloud = messageToCloud(message);
    await _client.setDocument(
      '$_requests/${message.requestId}/messages/${message.id}',
      messageToMap(cloud),
    );
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async {
    if (!isAvailable) return [];
    final docs =
        await _client.listCollection('$_requests/$requestId/messages');
    return docs.map(messageFromMap).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }
}
