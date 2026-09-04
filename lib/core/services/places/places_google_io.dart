import 'package:safarsure/core/services/places/places_api_result.dart';
import 'package:safarsure/core/services/places/places_google_new_client.dart';

Future<PlacesGoogleResult> fetchGooglePlaceSuggestions(String query) {
  return fetchPlacesNewAutocomplete(query);
}
