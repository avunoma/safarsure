import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/places_api_result.dart';
import 'package:safarsure/core/services/places/places_google_platform.dart';
import 'package:safarsure/core/services/places/places_utils.dart';

export 'package:safarsure/core/services/places/place_suggestion.dart';
export 'package:safarsure/core/services/places/places_api_result.dart';

class PlacesService {
  Future<PlacesAutocompleteResult> autocomplete(String query) async {
    final local = localPlaceSuggestions(query);

    if (!AppConfig.hasMapsApiKey) {
      return PlacesAutocompleteResult(suggestions: local);
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return PlacesAutocompleteResult(suggestions: local);
    }

    try {
      final google = await fetchGooglePlaceSuggestions(trimmed);
      return PlacesAutocompleteResult(
        suggestions: mergePlaceSuggestions(local, google.suggestions),
        mapsErrorHint: google.errorHint,
      );
    } catch (_) {
      return PlacesAutocompleteResult(
        suggestions: local,
        mapsErrorHint:
            'Google Places unavailable. Local cities still available.',
      );
    }
  }
}
