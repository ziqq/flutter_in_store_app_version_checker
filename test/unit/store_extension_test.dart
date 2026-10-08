/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_exception.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_extension.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../util/fake_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoreCheckUpdate.checkUpdate -', () {
    const request = StoreRequest(
      currentVersion: '1.0.0',
      packageName: 'test.app',
      locale: 'en-US',
    );

    test('maps a listing to a success response', () async {
      final response = await const FakeStore.listing(
        version: '2.0.0',
        appURL: 'https://example.com/app',
      ).checkUpdate(request);

      expect(response.isSuccess, isTrue);
      expect(response.currentVersion, '1.0.0');
      expect(response.newVersion, '2.0.0');
      expect(response.appURL, 'https://example.com/app');
      expect(response.canUpdate, isTrue);
    });

    test(
      'maps a listing without a version to a successful no-update',
      () async {
        final response = await const FakeStore.listing().checkUpdate(request);

        expect(response.isSuccess, isTrue);
        expect(response.newVersion, isNull);
        expect(response.canUpdate, isFalse);
      },
    );

    test('maps a store-reported failure without an underlying error', () async {
      final response = await const FakeStore.failure(
        AppStoreException(message: 'Store said no.'),
      ).checkUpdate(request);

      expect(response.isError, isTrue);
      expect(response.currentVersion, '1.0.0');
      expect(response.error, isNull);
      expect(response.errorMessage, 'Store said no.');
      expect(response.stackTrace, isNotNull);
    });

    test('maps a store-reported failure with its underlying error', () async {
      const underlyingError = FormatException('bad data');
      final response = await const FakeStore.failure(
        AppStoreException(message: 'Combined message.', error: underlyingError),
      ).checkUpdate(request);

      expect(response.error, same(underlyingError));
      expect(response.errorMessage, 'Combined message.');
    });

    test('maps any other error to error and toString()', () async {
      final error = StateError('boom');
      final response = await FakeStore.failure(error).checkUpdate(request);

      expect(response.isError, isTrue);
      expect(response.error, same(error));
      expect(response.errorMessage, error.toString());
      expect(response.newVersion, isNull);
      expect(response.appURL, isNull);
    });
  });

  group('Store-reported failures keep error == null -', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<InStoreAppVersionCheckerResponse> check(
      Future<http.Response> Function(http.Request request) handler, {
      InStoreAppVersionCheckerAndroidStoreType androidStore = .googlePlayStore,
    }) {
      final client = MockClient(handler);
      addTearDown(client.close);
      return InStoreAppVersionChecker.instanceFor(
        httpClient: client,
      ).checkUpdate(
        InStoreAppVersionCheckerParams(
          locale: 'en-US',
          packageName: 'test.app',
          currentVersion: '1.0.0',
          androidStore: androidStore,
        ),
      );
    }

    test('Apple App Store HTTP error', () async {
      debugDefaultTargetPlatformOverride = .iOS;
      final response = await check((_) async => http.Response('', 500));

      expect(response.isError, isTrue);
      expect(response.error, isNull);
      expect(
        response.errorMessage,
        'Apple Store lookup failed (HTTP 500) for bundle ID "test.app" '
        'in storefront "us" (locale: "en-US").',
      );
    });

    test('Apple App Store empty results', () async {
      debugDefaultTargetPlatformOverride = .iOS;
      final response = await check(
        (_) async => http.Response('{"results":[]}', 200),
      );

      expect(response.isError, isTrue);
      expect(response.error, isNull);
      expect(
        response.errorMessage,
        'App "test.app" was not found in the Apple Store storefront "us" '
        '(locale: "en-US"). Check the bundle ID and availability in this '
        'storefront.',
      );
    });

    test('ApkPure HTTP error', () async {
      debugDefaultTargetPlatformOverride = .android;
      final response = await check(
        (_) async => http.Response('', 404),
        androidStore: .apkPure,
      );

      expect(response.isError, isTrue);
      expect(response.error, isNull);
      expect(
        response.errorMessage,
        'Cannot find an app in the ApkPure Store with the id: test.app',
      );
    });

    test('PlayStoreApi HTTP error', () async {
      debugDefaultTargetPlatformOverride = .android;
      final response = await check(
        (request) async => switch (request.url.host) {
          'api.playstoreapi.com' => http.Response(
            '',
            503,
            reasonPhrase: 'Service Unavailable',
          ),
          _ => throw http.ClientException('offline'),
        },
      );

      expect(response.isError, isTrue);
      expect(response.error, isNull);
      expect(
        response.errorMessage,
        'PlayStoreApi error: 503 Service Unavailable. '
        'Google Play lookup: ClientException: offline',
      );
    });

    test(
      'Google Play fallback failure keeps the original error and stack',
      () async {
        debugDefaultTargetPlatformOverride = .android;
        final apiError = http.ClientException('api down');
        final apiStackTrace = StackTrace.fromString(
          'original PlayStoreApi stack',
        );
        final response = await check(
          (request) async => switch (request.url.host) {
            'api.playstoreapi.com' => Error.throwWithStackTrace(
              apiError,
              apiStackTrace,
            ),
            _ => throw http.ClientException('offline'),
          },
        );

        expect(response.isError, isTrue);
        expect(response.error, same(apiError));
        expect(response.stackTrace.toString(), apiStackTrace.toString());
        expect(
          response.errorMessage,
          'ClientException: api down Google Play lookup: ClientException: offline',
        );
      },
    );
  });
}
