import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';
import 'package:safarsure/core/services/places/places_utils.dart';

Future<List<PlaceSuggestion>> fetchGooglePlaceSuggestions(String query) async {
  if (!AppConfig.hasMapsApiKey) return [];

  final uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/place/autocomplete/json',
    {
      'input': query,
      'components': 'country:in',
      'key': AppConfig.mapsApiKey,
    },
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) return [];

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  if (data['status'] != 'OK') return [];

  final predictions = data['predictions'] as List<dynamic>;
  return predictions.map((p) {
    final description = p['description'] as String;
    return PlaceSuggestion(
      canonicalName: canonicalFromGoogleDescription(description),
      displayLabel: description,
      placeId: p['place_id'] as String?,
    );
  }).toList();
}
