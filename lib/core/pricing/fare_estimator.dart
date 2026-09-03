import 'package:intl/intl.dart';

/// Mock Ola/Uber fare estimates for intercity routes (no live API).
abstract final class FareEstimator {
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// City-pair Ola estimates (one-way, typical sedan).
  static const Map<String, int> _olaByRoute = {
    'bengaluru-chennai': 4800,
    'bengaluru-hyderabad': 5200,
    'bengaluru-mumbai': 8500,
    'chennai-bengaluru': 4600,
    'delhi-chandigarh': 2800,
    'delhi-jaipur': 3500,
    'hyderabad-bengaluru': 5100,
    'mumbai-pune': 2400,
    'pune-mumbai': 2200,
  };

  /// Fallback distance bands when route is not in the table (km → Ola estimate).
  static const List<(int maxKm, int fare)> _distanceBands = [
    (150, 2200),
    (300, 3800),
    (500, 5500),
    (800, 7800),
    (1200, 11000),
  ];

  static String routeKey(String from, String to) {
    final cities = [from.trim().toLowerCase(), to.trim().toLowerCase()]..sort();
    return '${cities[0]}-${cities[1]}';
  }

  static int estimateOlaFare(String fromCity, String toCity) {
    final key = routeKey(fromCity, toCity);
    if (_olaByRoute.containsKey(key)) {
      return _olaByRoute[key]!;
    }
    final estimatedKm = _guessDistanceKm(fromCity, toCity);
    for (final band in _distanceBands) {
      if (estimatedKm <= band.$1) {
        return band.$2;
      }
    }
    return 12000;
  }

  static int _guessDistanceKm(String from, String to) {
    final fromNorm = from.trim().toLowerCase();
    final toNorm = to.trim().toLowerCase();
    if (fromNorm == toNorm) return 25;
    if (fromNorm.contains('mumbai') || toNorm.contains('mumbai')) {
      if (fromNorm.contains('pune') || toNorm.contains('pune')) return 150;
    }
    if (fromNorm.contains('delhi') || toNorm.contains('delhi')) {
      if (fromNorm.contains('jaipur') || toNorm.contains('jaipur')) return 280;
      if (fromNorm.contains('chandigarh') || toNorm.contains('chandigarh')) {
        return 250;
      }
    }
    if ((fromNorm.contains('bengaluru') || fromNorm.contains('bangalore')) &&
        (toNorm.contains('chennai') || toNorm.contains('chennai'))) {
      return 350;
    }
    return 400;
  }

  static String formatInr(int amount) => _currency.format(amount);

  static int savingsAmount(int olaEstimate, int costSharePerSeat) =>
      (olaEstimate - costSharePerSeat).clamp(0, olaEstimate);

  static int savingsPercent(int olaEstimate, int costSharePerSeat) {
    if (olaEstimate <= 0) return 0;
    return ((savingsAmount(olaEstimate, costSharePerSeat) / olaEstimate) * 100)
        .round();
  }
}
