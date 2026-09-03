/// Canonical Indian cities for local autocomplete and trip matching.
const List<String> indianCities = [
  'Agra',
  'Ahmedabad',
  'Amritsar',
  'Aurangabad',
  'Bengaluru',
  'Bhopal',
  'Bhubaneswar',
  'Chandigarh',
  'Chennai',
  'Coimbatore',
  'Dehradun',
  'Delhi',
  'Goa',
  'Guwahati',
  'Gurgaon',
  'Hyderabad',
  'Indore',
  'Jaipur',
  'Jodhpur',
  'Kanpur',
  'Kochi',
  'Kolkata',
  'Lucknow',
  'Ludhiana',
  'Madurai',
  'Mangalore',
  'Mumbai',
  'Mysuru',
  'Nagpur',
  'Nashik',
  'Noida',
  'Patna',
  'Pune',
  'Raipur',
  'Ranchi',
  'Surat',
  'Thiruvananthapuram',
  'Tiruchirappalli',
  'Udaipur',
  'Vadodara',
  'Varanasi',
  'Visakhapatnam',
];

/// Maps common aliases and spellings to canonical city names.
const Map<String, String> cityAliasToCanonical = {
  'bangalore': 'Bengaluru',
  'bengaluru': 'Bengaluru',
  'bombay': 'Mumbai',
  'mumbai': 'Mumbai',
  'madras': 'Chennai',
  'chennai': 'Chennai',
  'calcutta': 'Kolkata',
  'kolkata': 'Kolkata',
  'trivandrum': 'Thiruvananthapuram',
  'thiruvananthapuram': 'Thiruvananthapuram',
  'gurgaon': 'Gurgaon',
  'gurugram': 'Gurgaon',
  'mysore': 'Mysuru',
  'mysuru': 'Mysuru',
  'vizag': 'Visakhapatnam',
  'visakhapatnam': 'Visakhapatnam',
  'trichy': 'Tiruchirappalli',
  'tiruchirappalli': 'Tiruchirappalli',
  'new delhi': 'Delhi',
  'delhi': 'Delhi',
  'ncr': 'Delhi',
  'panaji': 'Goa',
  'goa': 'Goa',
  'cochin': 'Kochi',
  'kochi': 'Kochi',
  'baroda': 'Vadodara',
  'vadodara': 'Vadodara',
  'mangaluru': 'Mangalore',
  'mangalore': 'Mangalore',
};

/// All searchable tokens for a city (canonical name + aliases).
Map<String, Set<String>> _citySearchTokens() {
  final tokens = <String, Set<String>>{};
  for (final city in indianCities) {
    tokens.putIfAbsent(city, () => {city.toLowerCase()});
  }
  cityAliasToCanonical.forEach((alias, canonical) {
    tokens.putIfAbsent(canonical, () => <String>{canonical.toLowerCase()});
    tokens[canonical]!.add(alias.toLowerCase());
  });
  return tokens;
}

final Map<String, Set<String>> _searchTokens = _citySearchTokens();

/// Resolves user input to a canonical city when possible.
String? resolveCanonicalCity(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (cityAliasToCanonical.containsKey(lower)) {
    return cityAliasToCanonical[lower];
  }

  for (final city in indianCities) {
    if (city.toLowerCase() == lower) return city;
  }

  for (final city in indianCities) {
    final tokens = _searchTokens[city] ?? {};
    if (tokens.any((t) => t.startsWith(lower) || lower.startsWith(t))) {
      return city;
    }
  }

  return null;
}

/// Whether [query] matches [cityName] including aliases and partial names.
bool cityMatches(String query, String cityName) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  final canonicalQuery = resolveCanonicalCity(query)?.toLowerCase();
  final canonicalCity = resolveCanonicalCity(cityName)?.toLowerCase() ??
      cityName.trim().toLowerCase();

  if (canonicalQuery != null && canonicalQuery == canonicalCity) {
    return true;
  }

  final tokens = _searchTokens[canonicalCity] ?? {canonicalCity};
  return tokens.any((t) => t.contains(q) || q.contains(t)) ||
      canonicalCity.contains(q) ||
      q.contains(canonicalCity);
}

/// Filter cities for autocomplete; empty query returns the full list.
List<String> filterCities(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return List<String>.from(indianCities);

  final lower = trimmed.toLowerCase();
  final matches = <String>{};

  for (final city in indianCities) {
    if (cityMatches(trimmed, city)) {
      matches.add(city);
    }
  }

  for (final entry in cityAliasToCanonical.entries) {
    if (entry.key.contains(lower) || lower.contains(entry.key)) {
      matches.add(entry.value);
    }
  }

  if (matches.isEmpty) {
    return [trimmed];
  }

  return matches.toList()
    ..sort((a, b) => a.compareTo(b));
}

/// Display label including a common alias when helpful.
String cityDisplayLabel(String canonical) {
  return switch (canonical) {
    'Bengaluru' => 'Bengaluru (Bangalore)',
    'Mumbai' => 'Mumbai (Bombay)',
    'Chennai' => 'Chennai (Madras)',
    'Kolkata' => 'Kolkata (Calcutta)',
    'Thiruvananthapuram' => 'Thiruvananthapuram (Trivandrum)',
    'Gurgaon' => 'Gurgaon (Gurugram)',
    'Mysuru' => 'Mysuru (Mysore)',
    'Kochi' => 'Kochi (Cochin)',
    _ => canonical,
  };
}
