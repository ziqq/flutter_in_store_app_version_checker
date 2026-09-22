import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(InStoreAppVersionCheckerResponse response) => MaterialApp(
    home: Scaffold(
      body: StoreResultSection(title: 'Store', item: response),
    ),
  );

  testWidgets('displays a successful store response', (tester) async {
    await tester.pumpWidget(
      appWith(
        const InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '2.0.0',
          appURL: 'https://example.com/app',
        ),
      ),
    );

    expect(find.text('Can update'), findsOneWidget);
    expect(find.text('Current version: 1.0.0'), findsOneWidget);
    expect(find.text('Store version: 2.0.0'), findsOneWidget);
    expect(find.text('App URL: https://example.com/app'), findsOneWidget);
  });

  testWidgets('displays an error response', (tester) async {
    await tester.pumpWidget(
      appWith(
        const InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          errorMessage: 'Store request failed.',
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Store request failed.'), findsOneWidget);
    expect(find.text('Can update'), findsNothing);
  });
}
