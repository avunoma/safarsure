import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/composite_cloud_sync.dart';
import 'package:safarsure/core/constants/app_constants.dart';
import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
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
    expect(cloudMap['driverRatingCount'], 12);

    final roundTrip = tripFromMap(cloudMap);
    expect(roundTrip.driverName, isEmpty);
    expect(roundTrip.fromCity, 'Bengaluru');
  });

  group('REST-only cloud sync', () {
    test('CompositeCloudSyncService does not require Firebase.initializeApp',
        () {
      expect(FirebaseService.isAvailable, isFalse);

      final cloud = CompositeCloudSyncService(rest: _FakeRestCloudSync());

      expect(cloud.isAvailable, isTrue);
    });

    test('AppRepository initializes with REST-only cloud sync', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = CompositeCloudSyncService(rest: _FakeRestCloudSync());
      final repo = AppRepository(prefs, cloud: cloud);

      await repo.initialize();

      expect(FirebaseService.isAvailable, isFalse);
      expect(cloud.isAvailable, isTrue);
      expect(repo.getTrips(), isNotEmpty);
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
      final found = results.firstWhere((t) => t.id == 'cloud-trip-1');
      expect(found.driverName, isEmpty);
      expect(found.driverRating, 4.7);
    });
  });
}

class _FakeRestCloudSync implements CloudSyncService {
  final List<Trip> _trips = [];

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
