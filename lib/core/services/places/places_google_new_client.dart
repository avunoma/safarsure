import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';
import 'package:safarsure/core/services/places/places_api_result.dart';
import 'package:safarsure/core/services/places/places_utils.dart';

const _autocompleteUrl =
    'https://places.googleapis.com/v1/places:autocomplete';

const _fieldMask =
    'suggestions.placePrediction.text,suggestions.placePrediction.placeId,suggestions.placePrediction.structuredFormat';

Future<PlacesGoogleResult> fetchPlacesNewAutocomplete(
  String query, {
  http.Client? client,
}) async {
  if (!AppConfig.hasMapsApiKey) {
    return const PlacesGoogleResult();
  }

  final ownsClient = client == null;
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.post(
      Uri.parse(_autocompleteUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': AppConfig.mapsApiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode({
        'input': query,
        'includedRegionCodes': ['in'],
        'languageCode': 'en',
      }),
    );

    if (response.statusCode == 200) {
      return parsePlacesNewAutocompleteBody(response.body);
    }

    return parsePlacesNewAutocompleteError(response.statusCode, response.body);
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

PlacesGoogleResult parsePlacesNewAutocompleteBody(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];
  final suggestions = <PlaceSuggestion>[];

  for (final raw in rawSuggestions) {
    if (raw is! Map<String, dynamic>) continue;
    final placePrediction = raw['placePrediction'];
    if (placePrediction is! Map<String, dynamic>) continue;

    final description = descriptionFromPlacePrediction(placePrediction);
    if (description.isEmpty) continue;

    suggestions.add(
      PlaceSuggestion(
        canonicalName: canonicalFromGoogleDescription(description),
        displayLabel: description,
        placeId: placePrediction['placeId'] as String?,
      ),
    );
  }

  return PlacesGoogleResult(suggestions: suggestions);
}

PlacesGoogleResult parsePlacesNewAutocompleteError(int statusCode, String body) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final error = json['error'] as Map<String, dynamic>?;
    final status = error?['status'] as String? ?? '';
    final message = error?['message'] as String? ?? body;
    return PlacesGoogleResult(
      errorHint: mapsErrorHintFromGoogleStatus(status, statusCode, message),
    );
  } catch (_) {
    return PlacesGoogleResult(
      errorHint: mapsErrorHintFromGoogleStatus('', statusCode, body),
    );
  }
}

String descriptionFromPlacePrediction(Map<String, dynamic> prediction) {
  final text = prediction['text'];
  if (text is Map<String, dynamic>) {
    final value = text['text'];
    if (value is String && value.isNotEmpty) return value;
  }

  final structured = prediction['structuredFormat'];
  if (structured is Map<String, dynamic>) {
    final main = structured['mainText'];
    final secondary = structured['secondaryText'];
    final mainText =
        main is Map<String, dynamic> ? main['text'] as String? : null;
    final secondaryText =
        secondary is Map<String, dynamic> ? secondary['text'] as String? : null;
    if (mainText != null && secondaryText != null) {
      return '$mainText, $secondaryText';
    }
    if (mainText != null) return mainText;
  }

  return '';
}
