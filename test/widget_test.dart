import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/core/constants/app_constants.dart';
import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/data/seed/seed_data.dart';

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
}
