import 'package:safarsure/core/constants/indian_cities.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';

/// Best canonical search value from a Google Places description string.
String canonicalFromGoogleDescription(String description) {
  final parts = description
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return description.trim();

  final first = parts.first;
  final firstCanonical = resolveCanonicalCity(first);
  if (firstCanonical != null) return firstCanonical;

  // Locality before a known city, e.g. "Koramangala, Bengaluru, Karnataka, India".
  if (parts.length > 1) return first;

  for (var i = 1; i < parts.length; i++) {
    final resolved = resolveCanonicalCity(parts[i]);
    if (resolved != null) return resolved;
  }

  return first;
}

List<PlaceSuggestion> localPlaceSuggestions(String query) {
  return filterCities(query)
      .map(
        (city) => PlaceSuggestion(
          canonicalName: city,
          displayLabel: cityDisplayLabel(city),
        ),
      )
      .toList();
}

List<PlaceSuggestion> mergePlaceSuggestions(
  List<PlaceSuggestion> local,
  List<PlaceSuggestion> google,
) {
  final seen = <String>{};
  final merged = <PlaceSuggestion>[];

  for (final item in [...local, ...google]) {
    final key = '${item.canonicalName}|${item.displayLabel}'.toLowerCase();
    if (seen.add(key)) {
      merged.add(item);
    }
  }
  return merged;
}
