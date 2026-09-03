import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/constants/indian_cities.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.description, this.placeId});

  final String description;
  final String? placeId;
}

class PlacesService {
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return indianCities
          .map((c) => PlaceSuggestion(description: c))
          .toList();
    }

    if (AppConfig.hasMapsApiKey) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/autocomplete/json',
          {
            'input': trimmed,
            'components': 'country:in',
            'key': AppConfig.mapsApiKey,
          },
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['status'] == 'OK') {
            final predictions = data['predictions'] as List<dynamic>;
            return predictions
                .map(
                  (p) => PlaceSuggestion(
                    description: p['description'] as String,
                    placeId: p['place_id'] as String?,
                  ),
                )
                .toList();
          }
        }
      } catch (_) {
        // Fall through to local list.
      }
    }

    return _localFallback(trimmed);
  }

  List<PlaceSuggestion> _localFallback(String query) {
    final lower = query.toLowerCase();
    final matches = indianCities
        .where((c) => c.toLowerCase().contains(lower))
        .map((c) => PlaceSuggestion(description: c))
        .toList();
    if (matches.isEmpty) {
      return [PlaceSuggestion(description: query)];
    }
    return matches;
  }
}
