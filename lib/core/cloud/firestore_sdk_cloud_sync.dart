import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';

class FirestoreSdkCloudSync implements CloudSyncService {
  FirestoreSdkCloudSync({FirebaseFirestore? firestore}) : _dbOverride = firestore;

  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore? _db;

  static const _requests = 'ride_requests';
  static const _syncCodes = 'sync_codes';

  @override
  bool get isAvailable => FirebaseService.isAvailable;

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return _dbOverride ?? (_db ??= FirebaseFirestore.instance);
  }

  CollectionReference<Map<String, dynamic>>? get _requestsCol =>
      _firestore?.collection(_requests);

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    final db = _firestore;
    final requestsCol = _requestsCol;
    if (db == null || requestsCol == null) return;

    final cloud = requestToCloud(request, revealRider: revealRider);
    await requestsCol
        .doc(request.id)
        .set(requestToMap(cloud), SetOptions(merge: true));
    if (request.syncCode != null) {
      await db.collection(_syncCodes).doc(request.syncCode).set({
        'requestId': request.id,
      });
    }
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async {
    final requestsCol = _requestsCol;
    if (requestsCol == null) return [];
    final snap = await requestsCol.where('tripId', isEqualTo: tripId).get();
    return snap.docs.map((d) => requestFromMap(d.data())).toList();
  }

  @override
  Future<RideRequest?> fetchRequestBySyncCode(String syncCode) async {
    final db = _firestore;
    if (db == null) return null;
    final index =
        await db.collection(_syncCodes).doc(syncCode.toUpperCase()).get();
    if (!index.exists) return null;
    final requestId = index.data()?['requestId'] as String?;
    if (requestId == null) return null;
    return fetchRequestById(requestId);
  }

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async {
    final requestsCol = _requestsCol;
    if (requestsCol == null) return null;
    final doc = await requestsCol.doc(requestId).get();
    if (!doc.exists) return null;
    return requestFromMap(doc.data()!);
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    final requestsCol = _requestsCol;
    if (requestsCol == null) return;
    final cloud = messageToCloud(message);
    await requestsCol
        .doc(message.requestId)
        .collection('messages')
        .doc(message.id)
        .set(messageToMap(cloud));
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async {
    final requestsCol = _requestsCol;
    if (requestsCol == null) return [];
    final snap = await requestsCol
        .doc(requestId)
        .collection('messages')
        .orderBy('sentAt')
        .get();
    return snap.docs.map((d) => messageFromMap(d.data())).toList();
  }
}
