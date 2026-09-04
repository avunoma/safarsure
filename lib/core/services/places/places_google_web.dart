import 'dart:async';
import 'dart:js_interop';

import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/services/places/place_suggestion.dart';
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

bool _loaded = false;

Future<void> _ensureLoaded() async {
  if (_loaded || !AppConfig.hasMapsApiKey) return;
  await _safarsurePlacesLoad(AppConfig.mapsApiKey).toDart;
  _loaded = true;
}

Future<List<PlaceSuggestion>> fetchGooglePlaceSuggestions(String query) async {
  if (!AppConfig.hasMapsApiKey) return [];
  try {
    await _ensureLoaded();
  } catch (_) {
    return [];
  }

  final completer = Completer<List<PlaceSuggestion>>();

  void onResult(JSAny? raw) {
    try {
      if (raw == null || !raw.isA<JSArray>()) {
        completer.complete([]);
        return;
      }
      final array = (raw as JSArray).toDart;
      final suggestions = <PlaceSuggestion>[];
      for (final item in array) {
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
      if (!completer.isCompleted) completer.complete(suggestions);
    } catch (_) {
      if (!completer.isCompleted) completer.complete([]);
    }
  }

  _safarsurePlacesAutocomplete(query, onResult.toJS);
  return completer.future;
}
