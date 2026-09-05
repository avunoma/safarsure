import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safarsure/core/cloud/firestore_rest_client.dart';
import 'package:safarsure/core/services/places/places_api_result.dart';
import 'package:safarsure/core/services/places/places_google_new_client.dart';
import 'package:safarsure/core/services/places/places_utils.dart';
import 'package:safarsure/core/widgets/place_autocomplete_field.dart';

void main() {
  group('canonicalFromGoogleDescription', () {
    test('maps alias in Google description to canonical city', () {
      expect(
        canonicalFromGoogleDescription('Bangalore, Karnataka, India'),
        'Bengaluru',
      );
    });

    test('keeps locality when followed by a known city', () {
      expect(
        canonicalFromGoogleDescription(
          'Koramangala, Bengaluru, Karnataka, India',
        ),
        'Koramangala',
      );
    });

    test('falls back to first segment for small towns', () {
      expect(
        canonicalFromGoogleDescription('Shimoga, Karnataka, India'),
        'Shimoga',
      );
    });
  });

  group('localPlaceSuggestions', () {
    test('stores canonical name separate from display label', () {
      final results = localPlaceSuggestions('ban');
      final match = results.firstWhere(
        (s) => s.canonicalName == 'Bengaluru',
      );
      expect(match.displayLabel, contains('Bangalore'));
    });

    test('empty query returns full scrollable local list', () {
      expect(localPlaceSuggestions('').length, greaterThan(15));
    });
  });

  group('Places API (New) parsing', () {
    test('parses autocomplete response into PlaceSuggestion list', () {
      const body = '''
{
  "suggestions": [
    {
      "placePrediction": {
        "placeId": "abc123",
        "text": { "text": "Koramangala, Bengaluru, Karnataka, India" },
        "structuredFormat": {
          "mainText": { "text": "Koramangala" },
          "secondaryText": { "text": "Bengaluru, Karnataka, India" }
        }
      }
    }
  ]
}
''';

      final result = parsePlacesNewAutocompleteBody(body);
      expect(result.suggestions, hasLength(1));
      expect(result.suggestions.first.canonicalName, 'Koramangala');
      expect(result.suggestions.first.placeId, 'abc123');
      expect(result.errorHint, isNull);
    });

    test('maps SERVICE_DISABLED to enable hint', () {
      const body = '''
{
  "error": {
    "code": 403,
    "message": "Places API (New) has not been used in project before or it is disabled.",
    "status": "PERMISSION_DENIED"
  }
}
''';

      final result = parsePlacesNewAutocompleteError(403, body);
      expect(result.suggestions, isEmpty);
      expect(result.errorHint, contains('Places API (New)'));
    });
  });

  group('mapsErrorHintFromGoogleStatus', () {
    test('surfaces permission denied for legacy API message', () {
      expect(
        mapsErrorHintFromGoogleStatus(
          'REQUEST_DENIED',
          403,
          'Legacy API not enabled',
        ),
        contains('Places API (New)'),
      );
    });
  });

  group('FirestoreRestClient quota handling', () {
    test('listCollection returns empty list on 429 and backs off', () async {
      final client = FirestoreRestClient(
        projectId: 'demo',
        apiKey: 'key',
        client: MockClient((request) async {
          return http.Response('Quota exceeded', 429);
        }),
      );

      expect(await client.listCollection('trips'), isEmpty);
      expect(await client.listCollection('trips'), isEmpty);
    });

    test('queryCollectionEqual parses structured query documents', () async {
      const body = '''
[
  {
    "document": {
      "name": "projects/demo/databases/(default)/documents/ride_requests/req-1",
      "fields": {
        "id": {"stringValue": "req-1"},
        "tripId": {"stringValue": "trip-1"},
        "riderId": {"stringValue": "rider-1"},
        "riderName": {"stringValue": "Rider"},
        "seats": {"integerValue": "1"},
        "status": {"stringValue": "waiting"}
      }
    }
  }
]
''';

      final client = FirestoreRestClient(
        projectId: 'demo',
        apiKey: 'key',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, endsWith(':runQuery'));
          return http.Response(body, 200);
        }),
      );

      final docs = await client.queryCollectionEqual(
        collectionId: 'ride_requests',
        fieldPath: 'tripId',
        equalTo: 'trip-1',
      );

      expect(docs, hasLength(1));
      expect(docs.first['tripId'], 'trip-1');
    });
  });

  testWidgets('selecting suggestion stores canonical name in controller',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PlaceAutocompleteField(
              label: 'Pickup',
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Bengaluru'), findsWidgets);
    expect(find.byType(ListView), findsOneWidget);

    await tester.tap(find.textContaining('Bengaluru').first);
    await tester.pump();
    // Past debounce + selecting hold — list must stay closed.
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.text, 'Bengaluru');
    expect(controller.text, isNot(contains('(')));
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('selection text change does not reopen suggestion list',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PlaceAutocompleteField(
              label: 'Pickup',
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.textContaining('Bengaluru').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.text, 'Bengaluru');
    expect(find.byType(ListView), findsNothing);

    // User taps field again to search — list should reopen.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ListView), findsOneWidget);
  });
}
