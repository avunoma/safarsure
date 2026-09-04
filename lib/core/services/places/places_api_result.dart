import 'package:safarsure/core/services/places/place_suggestion.dart';

/// Result from a Google Places autocomplete call.
class PlacesGoogleResult {
  const PlacesGoogleResult({
    this.suggestions = const [],
    this.errorHint,
  });

  final List<PlaceSuggestion> suggestions;
  final String? errorHint;
}

/// Combined local + Google autocomplete result for the UI.
class PlacesAutocompleteResult {
  const PlacesAutocompleteResult({
    required this.suggestions,
    this.mapsErrorHint,
  });

  final List<PlaceSuggestion> suggestions;
  final String? mapsErrorHint;
}

/// User-facing hint when Google returns permission / disabled errors.
String? mapsErrorHintFromGoogleStatus(
  String status,
  int statusCode,
  String message,
) {
  final normalizedStatus = status.toUpperCase();
  final normalizedMessage = message.toUpperCase();

  if (normalizedStatus.contains('PERMISSION_DENIED') ||
      normalizedStatus.contains('REQUEST_DENIED') ||
      normalizedMessage.contains('SERVICE_DISABLED') ||
      normalizedMessage.contains('HAS NOT BEEN USED') ||
      normalizedMessage.contains('LEGACY API') ||
      (statusCode == 403 && normalizedMessage.contains('API'))) {
    return 'Enable Places API (New) in Google Cloud Console (Maps JavaScript API for web).';
  }

  if (normalizedStatus.contains('RESOURCE_EXHAUSTED') || statusCode == 429) {
    return 'Google Places rate limit reached. Local cities still available.';
  }

  if (statusCode >= 400) {
    return 'Google Places request failed ($statusCode). Local cities still available.';
  }

  return null;
}
