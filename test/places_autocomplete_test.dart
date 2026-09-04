import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.tap(find.textContaining('Bengaluru').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.text, 'Bengaluru');
    expect(controller.text, isNot(contains('(')));
  });
}
