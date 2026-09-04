import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/features/trips/screens/my_rides_screen.dart';

void main() {
  testWidgets('JoinRideCodeDialog survives open, submit, and close', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (context) => const JoinRideCodeDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ABC123');
    await tester.pump();

    await tester.tap(find.text('Join'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(JoinRideCodeDialog), findsNothing);
  });

  testWidgets('JoinRideCodeDialog cancel closes without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (context) => const JoinRideCodeDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(JoinRideCodeDialog), findsNothing);
  });
}
