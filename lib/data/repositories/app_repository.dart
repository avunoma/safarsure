import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  AppRepository(this._prefs);

  final SharedPreferences _prefs;
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
    return trip;
  }

  Future<void> updateTrip(Trip trip) async {
    final trips = getTrips();
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
      await _saveTrips(trips);
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
    return request;
  }

  Future<void> updateRequest(RideRequest request) async {
    final requests = getRequests();
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      requests[index] = request;
      await _saveRequests(requests);
    }
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
    final normalizedFrom = fromCity.trim().toLowerCase();
    final normalizedTo = toCity.trim().toLowerCase();
    final now = DateTime.now();

    return getTrips().where((trip) {
      final fromMatch =
          trip.fromCity.toLowerCase().contains(normalizedFrom) ||
              normalizedFrom.contains(trip.fromCity.toLowerCase());
      final toMatch = trip.toCity.toLowerCase().contains(normalizedTo) ||
          normalizedTo.contains(trip.toCity.toLowerCase());
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

final appRepositoryProvider = FutureProvider<AppRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repo = AppRepository(prefs);
  await repo.initialize();
  return repo;
});
