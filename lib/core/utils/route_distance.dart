import 'package:safarsure/core/constants/indian_cities.dart';

/// Rough inter-city distances (km) for fuel-share estimation when no route API
/// is available. Keys are sorted canonical city pairs joined by '|'.
const Map<String, double> _knownRouteDistancesKm = {
  'Bengaluru|Chennai': 350,
  'Bengaluru|Hyderabad': 570,
  'Bengaluru|Mumbai': 980,
  'Bengaluru|Pune': 840,
  'Chennai|Hyderabad': 630,
  'Delhi|Jaipur': 280,
  'Delhi|Mumbai': 1420,
  'Delhi|Chandigarh': 250,
  'Gurgaon|Jaipur': 240,
  'Mumbai|Pune': 150,
  'Mumbai|Goa': 590,
  'Mumbai|Nashik': 165,
  'Hyderabad|Pune': 560,
  'Kolkata|Bhubaneswar': 440,
  'Chennai|Bengaluru': 350,
  'Chennai|Mumbai': 1330,
  'Delhi|Agra': 230,
  'Delhi|Lucknow': 550,
  'Pune|Goa': 450,
};

String _routeKey(String from, String to) {
  final a = resolveCanonicalCity(from);
  final b = resolveCanonicalCity(to);
  final sorted = [a, b]..sort();
  return '${sorted[0]}|${sorted[1]}';
}

/// Returns estimated distance in km for a city pair, or null if unknown.
double? estimateDistanceKm(String fromCity, String toCity) {
  if (fromCity.trim().isEmpty || toCity.trim().isEmpty) return null;
  final key = _routeKey(fromCity, toCity);
  return _knownRouteDistancesKm[key];
}
