import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/firestore_rest_client.dart';
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';

class FirestoreRestCloudSync implements CloudSyncService {
  FirestoreRestCloudSync({FirestoreRestClient? client})
      : _client = client ??
            FirestoreRestClient(
              projectId: AppConfig.demoFirebaseProjectId,
              apiKey: AppConfig.demoFirebaseApiKey,
            );

  final FirestoreRestClient _client;

  static const _requests = 'ride_requests';
  static const _syncCodes = 'sync_codes';

  @override
  bool get isAvailable => AppConfig.hasDemoCloudRest;

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    if (!isAvailable) return;
    final cloud = requestToCloud(request, revealRider: revealRider);
    final data = requestToMap(cloud);
    await _client.setDocument('$_requests/${request.id}', data);
    if (request.syncCode != null) {
      await _client.setDocument(
        '$_syncCodes/${request.syncCode}',
        {'requestId': request.id},
      );
    }
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async {
    if (!isAvailable) return [];
    final docs = await _client.listCollection(_requests);
    return docs
        .map(requestFromMap)
        .where((r) => r.tripId == tripId)
        .toList();
  }

  @override
  Future<RideRequest?> fetchRequestBySyncCode(String syncCode) async {
    if (!isAvailable) return null;
    final index =
        await _client.getDocument('$_syncCodes/${syncCode.toUpperCase()}');
    if (index == null) return null;
    return fetchRequestById(index['requestId'] as String);
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
