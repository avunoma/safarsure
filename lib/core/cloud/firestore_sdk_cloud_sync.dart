import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';

class FirestoreSdkCloudSync implements CloudSyncService {
  FirestoreSdkCloudSync({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _requests = 'ride_requests';
  static const _syncCodes = 'sync_codes';

  @override
  bool get isAvailable => FirebaseService.isAvailable;

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _db.collection(_requests);

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    if (!isAvailable) return;
    final cloud = requestToCloud(request, revealRider: revealRider);
    await _requestsCol.doc(request.id).set(requestToMap(cloud), SetOptions(merge: true));
    if (request.syncCode != null) {
      await _db.collection(_syncCodes).doc(request.syncCode).set({
        'requestId': request.id,
      });
    }
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async {
    if (!isAvailable) return [];
    final snap = await _requestsCol.where('tripId', isEqualTo: tripId).get();
    return snap.docs.map((d) => requestFromMap(d.data())).toList();
  }

  @override
  Future<RideRequest?> fetchRequestBySyncCode(String syncCode) async {
    if (!isAvailable) return null;
    final index = await _db.collection(_syncCodes).doc(syncCode.toUpperCase()).get();
    if (!index.exists) return null;
    final requestId = index.data()?['requestId'] as String?;
    if (requestId == null) return null;
    return fetchRequestById(requestId);
  }

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async {
    if (!isAvailable) return null;
    final doc = await _requestsCol.doc(requestId).get();
    if (!doc.exists) return null;
    return requestFromMap(doc.data()!);
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    if (!isAvailable) return;
    final cloud = messageToCloud(message);
    await _requestsCol
        .doc(message.requestId)
        .collection('messages')
        .doc(message.id)
        .set(messageToMap(cloud));
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async {
    if (!isAvailable) return [];
    final snap = await _requestsCol
        .doc(requestId)
        .collection('messages')
        .orderBy('sentAt')
        .get();
    return snap.docs.map((d) => messageFromMap(d.data())).toList();
  }
}
