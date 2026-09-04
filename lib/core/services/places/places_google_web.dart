import 'dart:async';
import 'dart:js_interop';

import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';
import 'package:safarsure/core/services/places/places_api_result.dart';
import 'package:safarsure/core/services/places/places_google_new_client.dart';
import 'package:safarsure/core/services/places/places_utils.dart';

@JS('safarsurePlacesLoad')
external JSPromise<JSAny?> _safarsurePlacesLoad(String apiKey);

@JS('safarsurePlacesAutocomplete')
external void _safarsurePlacesAutocomplete(String query, JSFunction callback);

@JS()
@anonymous
extension type _JsPlacePrediction._(JSObject _) implements JSObject {
  external String get description;
  external String get placeId;
}

@JS()
@anonymous
extension type _JsPlacesCallbackResult._(JSObject _) implements JSObject {
  external JSArray? get suggestions;
  external String? get error;
}

bool _loaded = false;

Future<void> _ensureJsLoaded() async {
  if (_loaded || !AppConfig.hasMapsApiKey) return;
  await _safarsurePlacesLoad(AppConfig.mapsApiKey).toDart;
  _loaded = true;
}

Future<PlacesGoogleResult> fetchGooglePlaceSuggestions(String query) async {
  if (!AppConfig.hasMapsApiKey) return const PlacesGoogleResult();

  try {
    final rest = await fetchPlacesNewAutocomplete(query);
    if (rest.suggestions.isNotEmpty || rest.errorHint != null) {
      return rest;
    }
  } on Object {
    // CORS or network failure — fall back to Maps JS Places API (New).
  }

  return _fetchViaJsBridge(query);
}

Future<PlacesGoogleResult> _fetchViaJsBridge(String query) async {
  try {
    await _ensureJsLoaded();
  } catch (_) {
    return const PlacesGoogleResult(
      errorHint:
          'Enable Places API (New) in Google Cloud Console (Maps JavaScript API for web).',
    );
  }

  final completer = Completer<PlacesGoogleResult>();

  void onResult(JSAny? raw) {
    try {
      if (raw == null || !raw.isA<_JsPlacesCallbackResult>()) {
        if (!completer.isCompleted) {
          completer.complete(const PlacesGoogleResult());
        }
        return;
      }

      final result = raw as _JsPlacesCallbackResult;
      final error = result.error;
      if (error != null && error.isNotEmpty) {
        if (!completer.isCompleted) {
          completer.complete(
            PlacesGoogleResult(
              errorHint: mapsErrorHintFromGoogleStatus(error, 403, error) ??
                  'Google Places unavailable. Local cities still available.',
            ),
          );
        }
        return;
      }

      final array = result.suggestions;
      if (array == null) {
        if (!completer.isCompleted) completer.complete(const PlacesGoogleResult());
        return;
      }

      final suggestions = <PlaceSuggestion>[];
      for (final item in array.toDart) {
        if (item == null || !item.isA<_JsPlacePrediction>()) continue;
        final prediction = item as _JsPlacePrediction;
        final description = prediction.description;
        suggestions.add(
          PlaceSuggestion(
            canonicalName: canonicalFromGoogleDescription(description),
            displayLabel: description,
            placeId: prediction.placeId,
          ),
        );
      }
      if (!completer.isCompleted) {
        completer.complete(PlacesGoogleResult(suggestions: suggestions));
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(const PlacesGoogleResult());
    }
  }

  _safarsurePlacesAutocomplete(query, onResult.toJS);
  return completer.future;
}
