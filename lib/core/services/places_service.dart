import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';
import 'package:safarsure/core/services/places/places_google_platform.dart';
import 'package:safarsure/core/services/places/places_utils.dart';

export 'package:safarsure/core/services/places/place_suggestion.dart';

class PlacesService {
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    final local = localPlaceSuggestions(query);

    if (!AppConfig.hasMapsApiKey) {
      return local;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return local;
    }

    try {
      final google = await fetchGooglePlaceSuggestions(trimmed);
      return mergePlaceSuggestions(local, google);
    } catch (_) {
      return local;
    }
  }
}
