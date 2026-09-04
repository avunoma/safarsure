import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/composite_cloud_sync.dart';
import 'package:safarsure/core/constants/app_constants.dart';
import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/core/utils/trip_sort.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/vehicle.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/data/seed/seed_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('seed data has at least 6 trips across city pairs', () {
    final trips = seedTrips();
    expect(trips.length, greaterThanOrEqualTo(6));

    final routes = trips.map((t) => '${t.fromCity}-${t.toCity}').toSet();
    expect(routes.length, greaterThanOrEqualTo(4));
  });

  test('leaving soon seed has at least 3 trips within 2 hours', () {
    final now = DateTime(2026, 9, 3, 10, 0);
    final soon = leavingSoonTrips(now);
    expect(soon.length, greaterThanOrEqualTo(3));
    for (final trip in soon) {
      expect(isLeavingSoonTrip(trip, now), isTrue);
    }
  });

  test('app constants are set', () {
    expect(AppConstants.appName, 'SafarSure');
    expect(AppConstants.tagline, 'Travel protected');
    expect(AppConstants.demoOtp, '123456');
  });

  test('city aliases match canonical names', () {
    expect(resolveCanonicalCity('Bangalore'), 'Bengaluru');
    expect(resolveCanonicalCity('bombay'), 'Mumbai');
    expect(resolveCanonicalCity('Trivandrum'), 'Thiruvananthapuram');
    expect(cityMatches('ban', 'Bengaluru'), isTrue);
    expect(cityMatches('Bangalore', 'Bengaluru'), isTrue);
    expect(cityMatches('Madras', 'Chennai'), isTrue);
  });

  test('filterCities returns full list when query is empty', () {
    expect(filterCities('').length, greaterThan(15));
    expect(filterCities('ban'), contains('Bengaluru'));
  });

  test('tripToCloud omits driver name for privacy', () {
    final trip = Trip(
      id: 't1',
      driverId: 'd1',
      driverName: 'Rahul Sharma',
      fromCity: 'Bengaluru',
      toCity: 'Chennai',
      departureTime: DateTime(2026, 9, 10, 8),
      seatsTotal: 3,
      seatsAvailable: 2,
      pricePerSeat: 500,
      vehicle: const Vehicle(make: 'Maruti', model: 'Swift', color: 'White'),
      driverRating: 4.8,
      driverRatingCount: 12,
    );

    final cloudMap = tripToMap(trip);
    expect(cloudMap.containsKey('driverName'), isFalse);
    expect(cloudMap['driverRating'], 4.8);

    final roundTrip = tripFromMap(cloudMap);
    expect(roundTrip.driverName, isEmpty);
  });

  test('sortTrips supports soonest, price, and rating', () {
    final base = DateTime(2026, 9, 10, 8);
    final trips = [
      Trip(
        id: 'a',
        driverId: 'd1',
        fromCity: 'A',
        toCity: 'B',
        departureTime: base.add(const Duration(hours: 2)),
        seatsTotal: 3,
        seatsAvailable: 2,
        pricePerSeat: 700,
        vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
        driverRating: 4.5,
      ),
      Trip(
        id: 'b',
        driverId: 'd2',
        fromCity: 'A',
        toCity: 'B',
        departureTime: base,
        seatsTotal: 3,
        seatsAvailable: 2,
        pricePerSeat: 500,
        vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
        driverRating: 4.9,
      ),
    ];

    expect(sortTrips(trips, TripSortOption.soonest).first.id, 'b');
    expect(sortTrips(trips, TripSortOption.lowestPrice).first.pricePerSeat, 500);
    expect(sortTrips(trips, TripSortOption.highestRating).first.driverRating, 4.9);
  });

  group('REST-only cloud sync', () {
    test('CompositeCloudSyncService does not require Firebase.initializeApp',
        () {
      expect(FirebaseService.isAvailable, isFalse);
      final cloud = CompositeCloudSyncService(rest: _FakeRestCloudSync());
      expect(cloud.isAvailable, isTrue);
    });

    test('published cloud trip appears in search on another device', () async {
      SharedPreferences.setMockInitialValues({});
      final cloud = _FakeRestCloudSync();

      final publisherPrefs = await SharedPreferences.getInstance();
      final publisherRepo = AppRepository(publisherPrefs, cloud: cloud);
      await publisherRepo.initialize();

      final published = Trip(
        id: 'cloud-trip-1',
        driverId: 'driver-remote',
        driverName: 'Hidden Driver',
        fromCity: 'Bengaluru',
        toCity: 'Chennai',
        departureTime: DateTime.now().add(const Duration(days: 2)),
        seatsTotal: 3,
        seatsAvailable: 2,
        pricePerSeat: 600,
        vehicle: const Vehicle(make: 'Hyundai', model: 'i20', color: 'Blue'),
        driverRating: 4.7,
        driverRatingCount: 9,
      );
      await publisherRepo.addTrip(published);

      SharedPreferences.setMockInitialValues({});
      final searcherPrefs = await SharedPreferences.getInstance();
      final searcherRepo = AppRepository(searcherPrefs, cloud: cloud);
      await searcherRepo.initialize();

      final results = searcherRepo.searchTrips(
        fromCity: 'Bangalore',
        toCity: 'Chennai',
        date: published.departureTime,
        seatsNeeded: 1,
      );

      expect(results.any((t) => t.id == 'cloud-trip-1'), isTrue);
    });

    test('rider request reaches driver via trip id without sync code', () async {
      SharedPreferences.setMockInitialValues({});
      final cloud = _FakeRestCloudSync();

      final driverPrefs = await SharedPreferences.getInstance();
      final driverRepo = AppRepository(driverPrefs, cloud: cloud);
      await driverRepo.initialize();

      const tripId = 'driver-trip-1';
      await driverRepo.addTrip(
        Trip(
          id: tripId,
          driverId: 'driver-1',
          driverName: 'Driver One',
          fromCity: 'Mumbai',
          toCity: 'Pune',
          departureTime: DateTime(2026, 9, 12, 9),
          seatsTotal: 3,
          seatsAvailable: 2,
          pricePerSeat: 450,
          vehicle: const Vehicle(make: 'Maruti', model: 'Swift', color: 'White'),
        ),
      );

      SharedPreferences.setMockInitialValues({});
      final riderPrefs = await SharedPreferences.getInstance();
      final riderRepo = AppRepository(riderPrefs, cloud: cloud);
      await riderRepo.initialize();
      await riderRepo.syncTripsFromCloud();

      await riderRepo.addRequest(
        RideRequest(
          id: 'req-1',
          tripId: tripId,
          riderId: 'rider-2',
          riderName: 'Rider Two',
          seats: 1,
          createdAt: DateTime.now(),
        ),
      );

      final changed = await driverRepo.syncFromCloud(
        driverTripIds: [tripId],
        riderUserId: 'driver-1',
      );

      expect(changed, isTrue);
      expect(
        driverRepo.getRequests().any((r) => r.id == 'req-1' && r.tripId == tripId),
        isTrue,
      );
    });
  });
}

class _FakeRestCloudSync implements CloudSyncService {
  final List<Trip> _trips = [];
  final List<RideRequest> _requests = [];

  @override
  bool get isAvailable => true;

  @override
  Future<void> upsertTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    final cloudTrip = tripFromMap(tripToMap(trip));
    if (index >= 0) {
      _trips[index] = cloudTrip;
    } else {
      _trips.add(cloudTrip);
    }
  }

  @override
  Future<List<Trip>> fetchTrips() async => List<Trip>.from(_trips);

  @override
  Future<void> upsertRequest(
    RideRequest request, {
    required bool revealRider,
  }) async {
    final index = _requests.indexWhere((r) => r.id == request.id);
    final cloud = requestToCloud(request, revealRider: revealRider);
    if (index >= 0) {
      _requests[index] = cloud;
    } else {
      _requests.add(cloud);
    }
  }

  @override
  Future<List<RideRequest>> fetchRequestsForTrip(String tripId) async =>
      _requests.where((r) => r.tripId == tripId).toList();

  @override
  Future<List<RideRequest>> fetchRequestsForRider(String riderId) async =>
      _requests.where((r) => r.riderId == riderId).toList();

  @override
  Future<RideRequest?> fetchRequestById(String requestId) async {
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {}

  @override
  Future<List<ChatMessage>> fetchMessages(String requestId) async => [];
}
