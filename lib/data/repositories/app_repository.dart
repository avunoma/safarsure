import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/composite_cloud_sync.dart';
import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/trip_rating.dart';
import 'package:safarsure/data/models/user.dart';
import 'package:safarsure/data/seed/seed_data.dart';
import 'package:uuid/uuid.dart';

const _tripsKey = 'safarsure_trips';
const _requestsKey = 'safarsure_requests';
const _messagesKey = 'safarsure_messages';
const _ratingsKey = 'safarsure_ratings';
const _userKey = 'safarsure_user';
const _initializedKey = 'safarsure_initialized';
const _seedVersionKey = 'safarsure_seed_version';
const _currentSeedVersion = 3;

class AppRepository {
  AppRepository(this._prefs, {CloudSyncService? cloud}) : _cloud = cloud;

  final SharedPreferences _prefs;
  final CloudSyncService? _cloud;
  final _uuid = const Uuid();

  Future<void> initialize() async {
    final seedVersion = _prefs.getInt(_seedVersionKey) ?? 0;
    if (seedVersion < _currentSeedVersion) {
      await _saveTrips(seedTrips());
      await _prefs.setInt(_seedVersionKey, _currentSeedVersion);
      await _prefs.setBool(_initializedKey, true);
    } else if (!(_prefs.getBool(_initializedKey) ?? false)) {
      await _saveTrips(seedTrips());
      await _prefs.setBool(_initializedKey, true);
    }
    await _syncLeavingSoonTrips();
    await syncTripsFromCloud();
  }

  Future<void> _syncLeavingSoonTrips() async {
    var trips = getTrips();
    trips = trips.where((t) => !leavingSoonTripIds.contains(t.id)).toList();
    trips.addAll(leavingSoonTrips());
    await _saveTrips(trips);
  }

  AppUser? getCurrentUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  List<Trip> getTrips() {
    final raw = _prefs.getString(_tripsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveTrips(List<Trip> trips) async {
    final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
    await _prefs.setString(_tripsKey, encoded);
  }

  Future<Trip> addTrip(Trip trip) async {
    final trips = getTrips()..add(trip);
    await _saveTrips(trips);
    await _cloudUpsertTrip(trip);
    return trip;
  }

  Future<void> updateTrip(Trip trip) async {
    final trips = getTrips();
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
      await _saveTrips(trips);
      await _cloudUpsertTrip(trip);
    }
  }

  Trip? getTripById(String id) {
    try {
      return getTrips().firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RideRequest> getRequests() {
    final raw = _prefs.getString(_requestsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveRequests(List<RideRequest> requests) async {
    final encoded = jsonEncode(requests.map((r) => r.toJson()).toList());
    await _prefs.setString(_requestsKey, encoded);
  }

  Future<RideRequest> addRequest(RideRequest request) async {
    final requests = getRequests()..add(request);
    await _saveRequests(requests);
    await _cloudUpsert(request, revealRider: false);
    return request;
  }

  Future<void> updateRequest(RideRequest request) async {
    final requests = getRequests();
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      requests[index] = request;
      await _saveRequests(requests);
      await _cloudUpsert(
        request,
        revealRider: request.status == RequestStatus.confirmed,
      );
    }
  }

  Future<bool> syncFromCloud({
    required List<String> driverTripIds,
    String? riderUserId,
  }) async {
    final cloud = _cloud;
    if (cloud == null || !cloud.isAvailable) return false;

    var changed = false;

    if (await syncTripsFromCloud()) changed = true;

    for (final tripId in driverTripIds) {
      final remoteRequests = await cloud.fetchRequestsForTrip(tripId);
      for (final remote in remoteRequests) {
        if (await _mergeRemoteRequest(remote)) changed = true;
      }
    }

    final riderRequests = riderUserId == null
        ? <RideRequest>[]
        : getRequests().where((r) => r.riderId == riderUserId);

    for (final local in riderRequests) {
      final remote = await cloud.fetchRequestById(local.id);
      if (remote != null && await _mergeRemoteRequest(remote)) {
        changed = true;
      }
    }

    for (final request in getRequests()) {
      if (request.status != RequestStatus.confirmed) continue;
      final remoteMessages = await cloud.fetchMessages(request.id);
      if (await _mergeRemoteMessages(request.id, remoteMessages)) {
        changed = true;
      }
    }

    return changed;
  }

  Future<bool> syncTripsFromCloud() async {
    final cloud = _cloud;
    if (cloud == null || !cloud.isAvailable) return false;
    final remoteTrips = await cloud.fetchTrips();
    return _mergeRemoteTrips(remoteTrips);
  }

  Future<void> _cloudUpsertTrip(Trip trip) async {
    final cloud = _cloud;
    if (cloud == null || !cloud.isAvailable) return;
    await cloud.upsertTrip(trip);
  }

  Future<bool> _mergeRemoteTrips(List<Trip> remoteTrips) async {
    if (remoteTrips.isEmpty) return false;

    final trips = getTrips();
    final indexById = <String, int>{};
    for (var i = 0; i < trips.length; i++) {
      indexById[trips[i].id] = i;
    }

    var changed = false;
    for (final remote in remoteTrips) {
      final index = indexById[remote.id];
      if (index == null) {
        trips.add(remote);
        indexById[remote.id] = trips.length - 1;
        changed = true;
        continue;
      }

      final merged = _mergeTripFields(trips[index], remote);
      if (merged != trips[index]) {
        trips[index] = merged;
        changed = true;
      }
    }

    if (changed) {
      await _saveTrips(trips);
    }
    return changed;
  }

  Trip _mergeTripFields(Trip local, Trip remote) {
    return remote.copyWith(
      driverName:
          local.driverName.isNotEmpty ? local.driverName : remote.driverName,
    );
  }

  Future<void> _cloudUpsert(
    RideRequest request, {
    required bool revealRider,
  }) async {
    final cloud = _cloud;
    if (cloud == null || !cloud.isAvailable) return;
    await cloud.upsertRequest(request, revealRider: revealRider);
  }

  Future<bool> _mergeRemoteRequest(RideRequest remote) async {
    final local = getRequestById(remote.id);
    if (local == null) {
      final requests = getRequests()..add(remote);
      await _saveRequests(requests);
      return true;
    }

    final merged = _mergeRequestFields(local, remote);
    if (merged == local) return false;

    final requests = getRequests();
    final index = requests.indexWhere((r) => r.id == remote.id);
    if (index >= 0) {
      requests[index] = merged;
      await _saveRequests(requests);
      return true;
    }
    return false;
  }

  RideRequest _mergeRequestFields(RideRequest local, RideRequest remote) {
    final remoteIsNewer = remote.status.index > local.status.index ||
        (remote.status == local.status &&
            remote.pickupPoint != null &&
            local.pickupPoint == null);

    if (!remoteIsNewer) return local;

    return local.copyWith(
      status: remote.status,
      pickupPoint: remote.pickupPoint ?? local.pickupPoint,
      pickupTime: remote.pickupTime ?? local.pickupTime,
      riderName: remote.status == RequestStatus.confirmed &&
              remote.riderName != 'Rider'
          ? remote.riderName
          : local.riderName,
    );
  }

  Future<bool> _mergeRemoteMessages(
    String requestId,
    List<ChatMessage> remoteMessages,
  ) async {
    if (remoteMessages.isEmpty) return false;

    final raw = _prefs.getString(_messagesKey);
    final all = raw == null
        ? <ChatMessage>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

    final existingIds = all.map((m) => m.id).toSet();
    var added = false;
    for (final message in remoteMessages) {
      if (existingIds.add(message.id)) {
        all.add(message);
        added = true;
      }
    }

    if (!added) return false;

    await _prefs.setString(
      _messagesKey,
      jsonEncode(all.map((m) => m.toJson()).toList()),
    );
    return true;
  }

  RideRequest? getRequestById(String id) {
    try {
      return getRequests().firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  String generateId() => _uuid.v4();

  List<Trip> getLeavingSoonTrips() {
    final now = DateTime.now();
    return getTrips().where((t) => isLeavingSoonTrip(t, now)).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }

  List<Trip> searchTrips({
    required String fromCity,
    required String toCity,
    required DateTime date,
    required int seatsNeeded,
    bool leavingSoonOnly = false,
  }) {
    final now = DateTime.now();

    return getTrips().where((trip) {
      final fromMatch = cityMatches(fromCity, trip.fromCity);
      final toMatch = cityMatches(toCity, trip.toCity);
      if (!fromMatch || !toMatch || trip.seatsAvailable < seatsNeeded) {
        return false;
      }
      if (leavingSoonOnly) {
        return isLeavingSoonTrip(trip, now);
      }
      final sameDay = trip.departureTime.year == date.year &&
          trip.departureTime.month == date.month &&
          trip.departureTime.day == date.day;
      return sameDay &&
          trip.departureTime.isAfter(now.subtract(const Duration(hours: 1)));
    }).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }

  List<ChatMessage> getMessagesForRequest(String requestId) {
    final raw = _prefs.getString(_messagesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .where((m) => m.requestId == requestId)
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Future<ChatMessage> sendMessage({
    required String requestId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final raw = _prefs.getString(_messagesKey);
    final all = raw == null
        ? <ChatMessage>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

    final message = ChatMessage(
      id: generateId(),
      requestId: requestId,
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      sentAt: DateTime.now(),
    );
    all.add(message);
    await _prefs.setString(
      _messagesKey,
      jsonEncode(all.map((m) => m.toJson()).toList()),
    );

    final cloud = _cloud;
    if (cloud != null && cloud.isAvailable) {
      await cloud.sendMessage(message);
    }

    return message;
  }

  List<TripRating> getRatings() {
    final raw = _prefs.getString(_ratingsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TripRating.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  bool hasRated(String requestId, String raterId) {
    return getRatings().any(
      (r) => r.requestId == requestId && r.raterId == raterId,
    );
  }

  Future<TripRating> submitRating({
    required String requestId,
    required String tripId,
    required String raterId,
    required String rateeId,
    required int stars,
    String comment = '',
  }) async {
    final ratings = getRatings();
    if (ratings.any((r) => r.requestId == requestId && r.raterId == raterId)) {
      throw StateError('Already rated');
    }

    final rating = TripRating(
      id: generateId(),
      requestId: requestId,
      tripId: tripId,
      raterId: raterId,
      rateeId: rateeId,
      stars: stars.clamp(1, 5),
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    ratings.add(rating);
    await _prefs.setString(
      _ratingsKey,
      jsonEncode(ratings.map((r) => r.toJson()).toList()),
    );

    final current = getCurrentUser();
    if (current != null && current.id == rateeId) {
      final summary = ratingSummaryForUser(
        rateeId,
        seedRating: current.rating,
        seedCount: current.ratingCount,
      );
      await saveUser(
        current.copyWith(
          rating: summary.average,
          ratingCount: summary.count,
        ),
      );
    }

    return rating;
  }

  ({double average, int count}) ratingSummaryForUser(
    String userId, {
    double seedRating = 4.5,
    int seedCount = 0,
  }) {
    final userRatings = getRatings().where((r) => r.rateeId == userId).toList();
    if (userRatings.isEmpty) {
      return (average: seedRating, count: seedCount);
    }
    final total = userRatings.fold<int>(0, (sum, r) => sum + r.stars);
    return (
      average: total / userRatings.length,
      count: userRatings.length + seedCount,
    );
  }
}

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CompositeCloudSyncService();
});

final appRepositoryProvider = FutureProvider<AppRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final cloud = ref.watch(cloudSyncServiceProvider);
  final repo = AppRepository(prefs, cloud: cloud);
  await repo.initialize();
  return repo;
});
