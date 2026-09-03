import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/firestore_rest_cloud_sync.dart';
import 'package:safarsure/core/cloud/firestore_sdk_cloud_sync.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';

class CompositeCloudSyncService implements CloudSyncService {
  CompositeCloudSyncService({
    CloudSyncService? sdk,
    CloudSyncService? rest,
  })  : _sdkOverride = sdk,
        _rest = rest ?? FirestoreRestCloudSync();

  final CloudSyncService? _sdkOverride;
  final CloudSyncService _rest;
  CloudSyncService? _sdk;

  /// Native Firestore is created only after Firebase.initializeApp() succeeds.
  CloudSyncService? get _sdkService {
    if (_sdkOverride != null) return _sdkOverride;
    if (!FirebaseService.isAvailable) return null;
    return _sdk ??= FirestoreSdkCloudSync();
  }

  CloudSyncService? get _active {
    final sdk = _sdkService;
    if (sdk != null && sdk.isAvailable) return sdk;
    if (_rest.isAvailable) return _rest;
    return null;
  }

  @override
  bool get isAvailable => _active != null;

  CloudSyncService get _service {
    final active = _active;
    if (active == null) {
      throw StateError('Cloud sync is not configured');
    }
    return active;
  }

  @override
  Future<void> upsertTrip(Trip trip) async {
    if (!isAvailable) return;
    await _service.upsertTrip(trip);
  }

  @override
  Future<List<Trip>> fetchTrips() async {
    if (!isAvailable) return [];
    return _service.fetchTrips();
  }

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    if (!isAvailable) return;
    await _service.upsertRequest(request, revealRider: revealRider);
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async {
    if (!isAvailable) return [];
    return _service.fetchRequestsForTrip(tripId);
  }

  @override
  Future<RideRequest?> fetchRequestBySyncCode(String syncCode) async {
    if (!isAvailable) return null;
    return _service.fetchRequestBySyncCode(syncCode);
  }

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async {
    if (!isAvailable) return null;
    return _service.fetchRequestById(requestId);
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    if (!isAvailable) return;
    await _service.sendMessage(message);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async {
    if (!isAvailable) return [];
    return _service.fetchMessages(requestId);
  }
}

class NoOpCloudSyncService implements CloudSyncService {
  @override
  bool get isAvailable => false;

  @override
  Future<void> upsertTrip(Trip trip) async {}

  @override
  Future<List<Trip>> fetchTrips() async => [];

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {}

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async => [];

  @override
  Future<RideRequest?> fetchRequestBySyncCode(String syncCode) async => null;

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async => null;

  @override
  Future<void> sendMessage(ChatMessage message) async {}

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async => [];
}
