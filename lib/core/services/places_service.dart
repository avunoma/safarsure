import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/constants/indian_cities.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.description, this.placeId});

  final String description;
  final String? placeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          runtimeType == other.runtimeType &&
          description == other.description;

  @override
  int get hashCode => description.hashCode;
}

class PlacesService {
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    final local = _localSuggestions(query);
    if (!AppConfig.hasMapsApiKey) {
      return local;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return local;
    }

    try {
      final google = await _googleSuggestions(trimmed);
      return _mergeSuggestions(local, google);
    } catch (_) {
      return local;
    }
  }

  List<PlaceSuggestion> _localSuggestions(String query) {
    return filterCities(query)
        .map((c) => PlaceSuggestion(description: cityDisplayLabel(c)))
        .toList();
  }

  Future<List<PlaceSuggestion>> _googleSuggestions(String query) async {
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
    return predictions
        .map(
          (p) => PlaceSuggestion(
            description: p['description'] as String,
            placeId: p['place_id'] as String?,
          ),
        )
        .toList();
  }

  List<PlaceSuggestion> _mergeSuggestions(
    List<PlaceSuggestion> local,
    List<PlaceSuggestion> google,
  ) {
    final seen = <String>{};
    final merged = <PlaceSuggestion>[];

    for (final item in [...local, ...google]) {
      final key = item.description.toLowerCase();
      if (seen.add(key)) {
        merged.add(item);
      }
    }
    return merged;
  }
}
