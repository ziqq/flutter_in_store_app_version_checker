import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../util/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );
  late List<Uri> requests;

  setUp(() {
    requests = <Uri>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => {'packageName': 'test.app', 'version': '1.0.0'},
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<InStoreAppVersionCheckerResponse> check(
    String body, {
    String apiBody = '{"version":"2.0.0"}',
    Exception? primaryError,
    Exception? apiError,
    InStoreAppVersionCheckerAndroidStoreType store =
        InStoreAppVersionCheckerAndroidStoreType.googlePlayStore,
  }) async {
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.host == 'api.playstoreapi.com') {
        if (apiError != null) throw apiError;
        return http.Response(apiBody, 200);
      }
      if (primaryError != null) throw primaryError;
      return http.Response(body, 200);
    });
    addTearDown(client.close);
    return InStoreAppVersionChecker.instanceFor(httpClient: client).checkUpdate(
      InStoreAppVersionCheckerParams(locale: 'en-US', androidStore: store),
    );
  }

  group('Apple listing validation', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    for (final version in <Object?>[null, '', '  ', 2, [], {}]) {
      test('rejects an invalid version ${jsonEncode(version)}', () async {
        final result = await check(
          jsonEncode({
            'results': [
              {'bundleId': 'test.app', 'version': version},
            ],
          }),
        );

        expect(result.isError, isTrue);
        expect(result.error, isA<FormatException>());
        expect(result.newVersion, isNull);
        expect(result.canUpdate, isFalse);
      });
    }

    for (final body in const [
      '{}',
      '[]',
      '{"results":{}}',
      '{"results":[{}]}',
      '{"results":[{"bundleId":"test.app"}]}',
      '{"results":[{"bundleId":"another.app","version":"99.0.0"}]}',
    ]) {
      test('rejects missing or mismatched listing data: $body', () async {
        final result = await check(body);

        expect(result.isError, isTrue);
        expect(result.error, isA<FormatException>());
        expect(result.newVersion, isNull);
      });
    }

    test('selects the requested bundle rather than the first result', () async {
      final result = await check(
        '{"results":['
        '{"bundleId":"another.app","version":"99.0.0"},'
        '{"bundleId":"test.app","version":"2.0.0"}]}',
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '2.0.0');
      expect(result.appURL, isNull);
    });

    for (final version in const ['1.0.0', '0.9.0']) {
      test('$version is a successful check without an update', () async {
        final result = await check(
          '{"results":[{"bundleId":"test.app","version":"$version"}]}',
        );

        expect(result.isSuccess, isTrue);
        expect(result.newVersion, version);
        expect(result.canUpdate, isFalse);
      });
    }
  });

  group('Google Play listing validation', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    for (final sparse in [false, true]) {
      for (final field in [140, 141]) {
        test('reads field $field with sparse=$sparse', () async {
          final result = await check(
            googlePlayListing(' 2026.09 ', sparse: sparse, versionField: field),
          );

          expect(result.isSuccess, isTrue);
          expect(result.newVersion, '2026.09');
          expect(requests, hasLength(1));
        });
      }
    }

    for (final entry in <String, String>{
      'analytics version': '<script>{"analyticsSdk":"99.0.0"}</script>',
      'unidentified array': ',[[["99.0.0"]],',
      'another package': googlePlayListing(
        '99.0.0',
        packageName: 'another.app',
      ),
      'empty version': googlePlayListing(''),
      'whitespace version': googlePlayListing('  '),
      'empty data':
          "AF_initDataCallback({key: 'ds:5', hash: '1', data:[], sideChannel: {}});",
      'empty object data':
          "AF_initDataCallback({key: 'ds:5', hash: '1', data:{}, sideChannel: {}});",
      'malformed data':
          "AF_initDataCallback({key: 'ds:5', hash: '1', data:{bad}, sideChannel: {}});",
    }.entries) {
      test('unrecognized ${entry.key} uses fallback', () async {
        final result = await check(entry.value);

        expect(result.isSuccess, isTrue);
        expect(result.newVersion, '2.0.0');
        expect(requests.map((uri) => uri.host), [
          'play.google.com',
          'api.playstoreapi.com',
        ]);
      });
    }

    test('ignores version strings outside the identified listing', () async {
      final result = await check(
        '<script>{"analyticsSdk":"99.0.0"}</script>'
        '${googlePlayListing('1.0.0', sparse: true)}',
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '1.0.0');
      expect(result.canUpdate, isFalse);
      expect(requests, hasLength(1));
    });

    test('transport errors still attempt fallback', () async {
      final result = await check(
        '',
        primaryError: http.ClientException('Connection reset'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '2.0.0');
      expect(requests, hasLength(2));
    });

    test('failure diagnostics describe both sources', () async {
      final result = await check(
        '',
        primaryError: http.ClientException('Primary connection reset'),
        apiError: http.ClientException('Fallback unavailable'),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('Primary connection reset'));
      expect(result.errorMessage, contains('Fallback unavailable'));
      expect(requests, hasLength(2));
    });

    for (final apiBody in const [
      '{}',
      '[]',
      '{"version":null}',
      '{"version":""}',
      '{"version":"  "}',
      '{"version":2}',
      '{"version":{}}',
    ]) {
      test('rejects an invalid fallback version: $apiBody', () async {
        final result = await check('<html></html>', apiBody: apiBody);

        expect(result.isError, isTrue);
        expect(result.error, isA<FormatException>());
        expect(result.newVersion, isNull);
        expect(result.canUpdate, isFalse);
      });
    }

    for (final version in const ['1.0.0', '0.9.0']) {
      test('fallback $version is success without an update', () async {
        final result = await check('', apiBody: '{"version":"$version"}');

        expect(result.isSuccess, isTrue);
        expect(result.newVersion, version);
        expect(result.canUpdate, isFalse);
      });
    }
  });

  group('ApkPure listing validation', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    for (final version in const ['', '  ']) {
      test('rejects an empty version "$version"', () async {
        final result = await check(
          '<div class="details-sdk"><span itemprop="version">$version</span>for Android</div>',
          store: InStoreAppVersionCheckerAndroidStoreType.apkPure,
        );

        expect(result.isError, isTrue);
        expect(result.error, isA<FormatException>());
        expect(result.newVersion, isNull);
        expect(result.canUpdate, isFalse);
      });
    }

    for (final version in const ['1.0.0', '0.9.0', '2026.09']) {
      test('accepts a published version "$version"', () async {
        final result = await check(
          '<div class="details-sdk"><span itemprop="version">$version</span>for Android</div>',
          store: InStoreAppVersionCheckerAndroidStoreType.apkPure,
        );

        expect(result.isSuccess, isTrue);
        expect(result.newVersion, version);
        expect(result.canUpdate, version == '2026.09');
      });
    }
  });
}
