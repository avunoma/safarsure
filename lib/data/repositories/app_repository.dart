import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/user.dart';
import 'package:safarsure/data/seed/seed_data.dart';
import 'package:uuid/uuid.dart';

const _tripsKey = 'safarsure_trips';
const _requestsKey = 'safarsure_requests';
const _userKey = 'safarsure_user';
const _initializedKey = 'safarsure_initialized';
const _seedVersionKey = 'safarsure_seed_version';
const _currentSeedVersion = 2;

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
