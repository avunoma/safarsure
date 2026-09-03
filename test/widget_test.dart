import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/core/cloud/cloud_sync_models.dart';
import 'package:safarsure/core/cloud/composite_cloud_sync.dart';
import 'package:safarsure/core/constants/app_constants.dart';
import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
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
  });
}

class _FakeRestCloudSync implements CloudSyncService {
  @override
  bool get isAvailable => true;

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
