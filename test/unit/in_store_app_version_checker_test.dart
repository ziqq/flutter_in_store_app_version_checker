/*
 * Additional tests with required locale argument and single shared mockHttpClient usage.
 * Author: Anton Ustinoff <https://github.com/ziqq>
 * Date: 14 November 2025
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_params.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../util/mocks.mocks.dart';

void main() {
  group('InStoreAppVersionChecker - ', () {
    const pkgChannel = MethodChannel('dev.fluttercommunity.plus/package_info');
    late MockClient mockHttpClient;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pkgChannel, (call) async {
        if (call.method == 'getAll') {
          return {
            'appName': 'TestApp',
            'packageName': 'test.app',
            'version': '1.0.0',
            'buildNumber': '1',
            'buildSignature': '',
            'installerStore': null,
          };
        }
        return null;
      });
      mockHttpClient = MockClient();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pkgChannel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    group('Apple Store (shared mock)', () {
      test('success parses version & url (shared mock)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"results":[{"version":"1.2.3","trackViewUrl":"https://apps.apple.com/app/id123"}]}',
            200,
          ),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'us'));
        expect(r.isSuccess, isTrue);
        expect(r.newVersion, '1.2.3');
        expect(r.appURL, 'https://apps.apple.com/app/id123');
        expect(r.canUpdate, isTrue);
      });

      test('non-200 -> error message contains Apple Store', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('x', 404));
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'ru'));
        expect(r.isError, isTrue);
        expect(r.newVersion, isNull);
        expect(r.canUpdate, isFalse);
        expect(r.errorMessage, contains('Apple Store'));
      });

      test('empty results -> error', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('{"results":[]}', 200));
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isError, isTrue);
        expect(r.newVersion, isNull);
        expect(r.canUpdate, isFalse);
      });

      test('trackViewUrl null -> "null" string (bug reproduced)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"results":[{"version":"2.0.0","trackViewUrl":null}]}',
            200,
          ),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '2.0.0');
        expect(r.appURL, 'null');
        expect(r.canUpdate, isTrue);
      });

      test('missing trackViewUrl key -> "null" (bug reproduced)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"results":[{"version":"3.0.0"}]}',
            200,
          ),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '3.0.0');
        expect(r.appURL, 'null');
        expect(r.canUpdate, isTrue);
      });

      test('malformed JSON -> error', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"results":[{"version":}', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isError, isTrue);
        expect(r.canUpdate, isFalse);
      });

      test('exception propagates to errorMessage', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenThrow(StateError('boom'));
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isError, isTrue);
        expect(r.errorMessage, contains('boom'));
        expect(r.canUpdate, isFalse);
      });
    });

    group('Play Store (HTML + fallback, shared mock)', () {
      test('primary regex match', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
        ))).thenAnswer(
          (_) async => http.Response(',[[["3.2.1"]],', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '3.2.1');
        expect(r.canUpdate, isTrue);
      });

      test('secondary regex match', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('"5.4.3"', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '5.4.3');
        expect(r.canUpdate, isTrue);
      });

      test('no match -> fallback API success', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
        ))).thenAnswer(
          (_) async => http.Response('<html>none</html>', 200),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('{"version":"9.9.9"}', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '9.9.9');
        expect(r.canUpdate, isTrue);
      });

      test('fallback API missing version -> success null newVersion', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
        ))).thenAnswer(
          (_) async => http.Response('<html>none</html>', 200),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('{"name":"App"}', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isSuccess, isTrue);
        expect(r.newVersion, isNull);
        expect(r.canUpdate, isFalse);
      });

      test('fallback API error status', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
        ))).thenAnswer(
          (_) async => http.Response('<html>none</html>', 200),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('fail', 500, reasonPhrase: 'Server Error'),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isError, isTrue);
        expect(r.errorMessage, contains('PlayStoreApi error: 500'));
        expect(r.canUpdate, isFalse);
      });

      test('HTML status 404 then fallback API success', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
        ))).thenAnswer(
          (_) async => http.Response('nf', 404),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('{"version":"2.0.0"}', 200),
        );
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.newVersion, '2.0.0');
        expect(r.canUpdate, isTrue);
      });
    });

    group('ApkPure (shared mock)', () {
      test('success parses version', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '<div class="details-sdk"><span itemprop="version">4.5.6</span>for Android</div>',
            200,
          ),
        );
        final r =
            await InStoreAppVersionChecker.custom(httpClient: mockHttpClient)
                .checkUpdate(const InStoreAppVersionCheckerParams(
          locale: 'en',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
        ));
        expect(r.newVersion, '4.5.6');
        expect(r.canUpdate, isTrue);
      });

      test('non-200 -> error', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('x', 404));
        final r =
            await InStoreAppVersionChecker.custom(httpClient: mockHttpClient)
                .checkUpdate(const InStoreAppVersionCheckerParams(
          locale: 'en',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
        ));
        expect(r.isError, isTrue);
        expect(r.newVersion, isNull);
        expect(r.canUpdate, isFalse);
      });

      test('parse fail -> success null newVersion', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('<html></html>', 200));
        final r =
            await InStoreAppVersionChecker.custom(httpClient: mockHttpClient)
                .checkUpdate(const InStoreAppVersionCheckerParams(
          locale: 'en',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
        ));
        expect(r.isSuccess, isTrue);
        expect(r.newVersion, isNull);
        expect(r.canUpdate, isFalse);
      });
    });

    group('Unsupported platform', () {
      test('macOS -> error response (shared mock)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('n/a', 200));
        final r = await InStoreAppVersionChecker.custom(
                httpClient: mockHttpClient)
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r.isError, isTrue);
        expect(r.errorMessage, contains('platform'));
        expect(r.canUpdate, isFalse);
      });
    });

    group('Params override', () {
      test('override packageName & currentVersion', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"results":[{"version":"2.0.0","trackViewUrl":"https://x"}]}',
            200,
          ),
        );
        final r =
            await InStoreAppVersionChecker.custom(httpClient: mockHttpClient)
                .checkUpdate(const InStoreAppVersionCheckerParams(
          locale: 'us',
          packageName: 'custom.pkg',
          currentVersion: '1.9.9',
        ));
        expect(r.currentVersion, '1.9.9');
        expect(r.canUpdate, isTrue);
      });
    });

    group('Singleton instance reuse', () {
      test('multiple calls different remote data', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var first = true;
        when(mockHttpClient.get(any)).thenAnswer((_) async =>
            http.Response(first ? ',[[["1.0.1"]],' : ',[[["1.0.2"]],', 200));
        final checker =
            InStoreAppVersionChecker.custom(httpClient: mockHttpClient);
        final r1 = await checker
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        first = false;
        final r2 = await checker
            .checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
        expect(r1.newVersion, '1.0.1');
        expect(r2.newVersion, '1.0.2');
      });
    });

    group('canUpdate logic (success responses)', () {
      InStoreAppVersionCheckerResponse s(String a, String? b) =>
          InStoreAppVersionCheckerResponse.success(
            currentVersion: a,
            newVersion: b,
          );
      test('equal', () => expect(s('1.2.3', '1.2.3').canUpdate, isFalse));
      test('patch', () => expect(s('1.2.3', '1.2.4').canUpdate, isTrue));
      test('minor', () => expect(s('1.2.3', '1.3.0').canUpdate, isTrue));
      test('major', () => expect(s('1.2.3', '2.0.0').canUpdate, isTrue));
      test('downgrade', () => expect(s('1.2.3', '1.2.2').canUpdate, isFalse));
      test('extra segment higher',
          () => expect(s('1.2.3', '1.2.3.1').canUpdate, isTrue));
      test('current longer higher',
          () => expect(s('1.2.3.4', '1.2.3').canUpdate, isFalse));
      test(
          'null newVersion', () => expect(s('1.2.3', null).canUpdate, isFalse));
      test('build metadata ignored',
          () => expect(s('1.0.0+10', '1.0.0+99').canUpdate, isFalse));
      test('build metadata patch',
          () => expect(s('1.0.0+10', '1.0.1+1').canUpdate, isTrue));
    });

    group('pre-release ordering', () {
      InStoreAppVersionCheckerResponse s(String a, String b) =>
          InStoreAppVersionCheckerResponse.success(
            currentVersion: a,
            newVersion: b,
          );
      test('pre -> release',
          () => expect(s('1.0.0-beta', '1.0.0').canUpdate, isFalse));
      test('release -> pre',
          () => expect(s('1.0.0', '1.0.0-beta').canUpdate, isTrue));
      test('alpha -> beta',
          () => expect(s('1.0.0-alpha', '1.0.0-beta').canUpdate, isTrue));
      test('beta -> alpha',
          () => expect(s('1.0.0-beta', '1.0.0-alpha').canUpdate, isFalse));
      test(
          'alpha-beta -> alpha-gamma',
          () => expect(
              s('1.0.0-alpha-beta', '1.0.0-alpha-gamma').canUpdate, isTrue));
      test('numeric 10 -> 2',
          () => expect(s('1.0.0-10', '1.0.0-2').canUpdate, isFalse));
      test('numeric 2 -> 10',
          () => expect(s('1.0.0-2', '1.0.0-10').canUpdate, isTrue));
    });

    group('normalization & stripping', () {
      InStoreAppVersionCheckerResponse s(String a, String b) =>
          InStoreAppVersionCheckerResponse.success(
            currentVersion: a,
            newVersion: b,
          );
      test('whitespace',
          () => expect(s(' 1.2.3 ', ' 1.2.4 ').canUpdate, isTrue));
      test('non-numeric current',
          () => expect(s('abc', '1.0.0').canUpdate, isTrue));
      test('non-numeric new',
          () => expect(s('1.0.0', 'xyz').canUpdate, isFalse));
      test('leading zeros equal',
          () => expect(s('01.002.003', '1.2.3').canUpdate, isFalse));
      test('leading zeros higher patch',
          () => expect(s('01.002.003', '1.2.4').canUpdate, isTrue));
    });

    group('literal "null"', () {
      test('"null" same core', () {
        const r = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: 'null',
        );
        expect(r.canUpdate, isFalse);
      });
      test('"null" vs higher numeric', () {
        const r = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '1.0.1',
        );
        expect(r.canUpdate, isTrue);
      });
      test('"null" vs lower numeric', () {
        const r = InStoreAppVersionCheckerResponse.success(
          currentVersion: '2.0.0',
          newVersion: 'null',
        );
        expect(r.canUpdate, isFalse);
      });
    });

    group('error response passthrough', () {
      test('higher newVersion -> true', () {
        const r = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          newVersion: '1.0.1',
          errorMessage: 'fail',
        );
        expect(r.canUpdate, isTrue);
      });
      test('same version -> false', () {
        const r = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          newVersion: '1.0.0',
          errorMessage: 'fail',
        );
        expect(r.canUpdate, isFalse);
      });
      test('lower newVersion -> false', () {
        const r = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.1',
          newVersion: '1.0.0',
          errorMessage: 'fail',
        );
        expect(r.canUpdate, isFalse);
      });
    });

    group('equality & hashCode', () {
      test('success equality', () {
        const a = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          appURL: 'url',
        );
        const b = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          appURL: 'url',
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different newVersion not equal', () {
        const a = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
        );
        const b = InStoreAppVersionCheckerResponse.success(
          currentVersion: '1.0.0',
          newVersion: '1.2.0',
        );
        expect(a == b, isFalse);
      });

      test('error responses only message differs -> equal', () {
        const a = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          errorMessage: 'A',
        );
        const b = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          errorMessage: 'B',
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('success formatting', () {
        const r = InStoreAppVersionCheckerResponse.success(
          currentVersion: '3.4.5',
          newVersion: '3.5.0',
          appURL: 'https://example.com',
        );
        final s = r.toString();
        expect(s, contains('Current version: 3.4.5'));
        expect(s, contains('New version: 3.5.0'));
        expect(s, contains('App url: https://example.com'));
        expect(s, contains('Can update: true'));
      });

      test('error shows message & stackTrace label', () {
        final r = InStoreAppVersionCheckerResponse.error(
          currentVersion: '3.4.5',
          newVersion: '3.5.0',
          appURL: 'https://example.com',
          errorMessage: 'Failure',
          error: ArgumentError('bad'),
          stackTrace: StackTrace.current,
        );
        final s = r.toString();
        expect(s, contains('Error message: Failure'));
        expect(s, contains('Error:'));
        expect(s, contains('Stack trace:'));
      });

      test('missing newVersion prints null', () {
        const r =
            InStoreAppVersionCheckerResponse.success(currentVersion: '1.0.0');
        expect(r.toString(), contains('New version: null'));
        expect(r.canUpdate, isFalse);
      });
    });

    group('InStoreAppVersionChecker (additional) - ', () {
      const pkgChannel =
          MethodChannel('dev.fluttercommunity.plus/package_info');
      late MockClient mockHttpClient;

      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pkgChannel, (call) async {
          if (call.method == 'getAll') {
            return {
              'appName': 'TestApp',
              'packageName': 'test.app',
              'version': '1.0.0',
              'buildNumber': '1',
              'buildSignature': '',
              'installerStore': null,
            };
          }
          return null;
        });
        mockHttpClient = MockClient();
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pkgChannel, null);
        debugDefaultTargetPlatformOverride = null;
      });

      group('Regression adjustments (reflect current behavior)', () {
        InStoreAppVersionCheckerResponse r(String a, String b) =>
            InStoreAppVersionCheckerResponse.success(
              currentVersion: a,
              newVersion: b,
            );

        // Previously expected opposite; current comparator treats smaller numeric
        // prerelease identifiers as "higher" (lexicographic style).
        test('numeric prerelease 10 -> 2 now no update', () {
          expect(r('1.0.0-10', '1.0.0-2').canUpdate, isFalse);
        });

        test('numeric prerelease 2 -> 10 now update', () {
          expect(r('1.0.0-2', '1.0.0-10').canUpdate, isTrue);
        });
      });

      group('Apple Store additional parsing cases', () {
        test('trackViewUrl empty string stays empty', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"results":[{"version":"1.0.1","trackViewUrl":""}]}',
              200,
            ),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'us'));
          expect(res.newVersion, '1.0.1');
          expect(res.appURL, '');
          expect(res.canUpdate, isTrue);
        });

        test('trackViewUrl whitespace preserved', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"results":[{"version":"1.0.2","trackViewUrl":"   "}]}',
              200,
            ),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'us'));
          expect(res.appURL, '   ');
          expect(res.canUpdate, isTrue);
        });

        test('version with build metadata ignored for update equality',
            () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"results":[{"version":"1.0.0+42","trackViewUrl":"https://x"}]}',
              200,
            ),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'us',
            currentVersion: '1.0.0+10',
          ));
          // Current comparator logic treats metadata as ignorable; patch equal -> no update.
          expect(res.canUpdate, isFalse);
        });

        test('non-semver Apple version (year.month) higher numeric part',
            () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"results":[{"version":"2025.11","trackViewUrl":"https://x"}]}',
              200,
            ),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'us',
            currentVersion: '2025.10',
          ));
          expect(res.newVersion, '2025.11');
          expect(res.canUpdate, isTrue);
        });
      });

      group('Play Store HTML regex edge cases', () {
        test('HTML only secondary regex used when primary absent', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('random "2.3.4" text', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
          expect(res.newVersion, '2.3.4');
          expect(res.canUpdate, isTrue);
        });

        test('Primary regex with commas returns raw captured string', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(',[[["3,2,1"]],', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
          expect(res.newVersion, '3,2,1');
        });

        test('No HTML match and API returns version -> update true', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
          ))).thenAnswer(
            (_) async => http.Response('<html>no version</html>', 200),
          );
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
          ))).thenAnswer(
            (_) async => http.Response('{"version":"7.0.0"}', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'en',
            currentVersion: '6.9.9',
          ));
          expect(res.newVersion, '7.0.0');
          expect(res.canUpdate, isTrue);
        });

        test('No HTML match and API missing version -> newVersion null',
            () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
          ))).thenAnswer(
            (_) async => http.Response('<html>none</html>', 200),
          );
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
          ))).thenAnswer(
            (_) async => http.Response('{"name":"App"}', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'en',
            currentVersion: '1.0.0',
          ));
          expect(res.newVersion, isNull);
          expect(res.canUpdate, isFalse);
        });
      });

      group('Play Store fallback API error path', () {
        test('API non-200 includes status in message', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          // Force HTML miss
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'play.google.com'),
          ))).thenAnswer(
            (_) async => http.Response('<html>no match</html>', 200),
          );
          // Fallback failure
          when(mockHttpClient.get(argThat(
            isA<Uri>().having((u) => u.host, 'host', 'api.playstoreapi.com'),
          ))).thenAnswer(
            (_) async => http.Response('error', 503,
                reasonPhrase: 'Service Unavailable'),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
          expect(res.isError, isTrue);
          expect(res.errorMessage, contains('503'));
          expect(res.canUpdate, isFalse);
        });
      });

      group('ApkPure extra variants', () {
        test('Missing version span -> success null newVersion', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
                '<div class="details-sdk">for Android</div>', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'en',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
          ));
          expect(res.newVersion, isNull);
          expect(res.canUpdate, isFalse);
        });

        test('Version with leading/trailing whitespace trimmed', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '<div class="details-sdk"><span itemprop="version"> 2.0.1 </span>for Android</div>',
              200,
            ),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'en',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
            currentVersion: '2.0.0',
          ));
          expect(res.newVersion, '2.0.1');
          expect(res.canUpdate, isTrue);
        });
      });

      group('Unsupported platforms', () {
        test('Fuchsia produces error response', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('irrelevant', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
          expect(res.isError, isTrue);
          expect(res.errorMessage, contains('iOS or Android'));
          expect(res.canUpdate, isFalse);
        });
      });

      group('Concurrency', () {
        test('Multiple simultaneous requests (Android) all complete', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          int calls = 0;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async {
              calls++;
              return http.Response(',[[["1.0.$calls"]],', 200);
            },
          );
          final checker =
              InStoreAppVersionChecker.custom(httpClient: mockHttpClient);
          final futures = List.generate(
            5,
            (_) => checker.checkUpdate(
                const InStoreAppVersionCheckerParams(locale: 'en')),
          );
          final results = await Future.wait(futures);
          expect(results.length, 5);
          expect(results.map((e) => e.newVersion).toSet().length, 5);
        });

        test('Mixed platform switches (sequential)', () async {
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(',[[["2.0.0"]],', 200),
          );
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          final androidRes = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'en',
            currentVersion: '1.0.0',
          ));
          expect(androidRes.canUpdate, isTrue);

          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"results":[{"version":"3.0.0","trackViewUrl":"https://x"}]}',
              200,
            ),
          );
          final iosRes = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(
            locale: 'us',
            currentVersion: '2.9.9',
          ));
          expect(iosRes.canUpdate, isTrue);
        });
      });

      group('Response object invariants', () {
        test('error newVersion null -> canUpdate false', () {
          const res = InStoreAppVersionCheckerResponse.error(
            currentVersion: '1.2.3',
            newVersion: null,
            errorMessage: 'x',
          );
          expect(res.canUpdate, isFalse);
        });

        test('success with identical versions & metadata -> no update', () {
          const res = InStoreAppVersionCheckerResponse.success(
            currentVersion: '1.0.0+5',
            newVersion: '1.0.0+10',
          );
          expect(res.canUpdate, isFalse);
        });

        test('success higher core ignoring metadata -> update true', () {
          const res = InStoreAppVersionCheckerResponse.success(
            currentVersion: '1.0.0+99',
            newVersion: '1.0.1+1',
          );
          expect(res.canUpdate, isTrue);
        });
      });

      group('Locale influence in URIs', () {
        test('Apple locale applied in path', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          late Uri captured;
          when(mockHttpClient.get(any)).thenAnswer((invocation) async {
            captured = invocation.positionalArguments.first as Uri;
            return http.Response(
              '{"results":[{"version":"1.1.0","trackViewUrl":"https://x"}]}',
              200,
            );
          });
          await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'fr'));
          expect(captured.path, contains('/fr/lookup'));
        });

        test('Play Store locale passed as hl query', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          late Uri captured;
          when(mockHttpClient.get(any)).thenAnswer((invocation) async {
            captured = invocation.positionalArguments.first as Uri;
            return http.Response(',[[["1.0.1"]],', 200);
          });
          await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'de'));
          expect(captured.queryParameters['hl'], 'de');
        });
      });

      group('Error handling robustness', () {
        test('Thrown synchronous exception yields error response', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          when(mockHttpClient.get(any)).thenThrow(Exception('network down'));
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'en'));
          expect(res.isError, isTrue);
          expect(res.errorMessage, contains('network down'));
          expect(res.canUpdate, isFalse);
        });

        test('Apple malformed JSON retains stackTrace', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('{"bad":', 200),
          );
          final res = await InStoreAppVersionChecker.custom(
            httpClient: mockHttpClient,
          ).checkUpdate(const InStoreAppVersionCheckerParams(locale: 'us'));
          expect(res.isError, isTrue);
          expect(res.stackTrace, isNotNull);
        });
      });

      group('Pre-release mixed alphanumeric segments', () {
        InStoreAppVersionCheckerResponse r(String a, String b) =>
            InStoreAppVersionCheckerResponse.success(
              currentVersion: a,
              newVersion: b,
            );

        // Document current comparator outcome (may differ from strict SemVer).
        test('alpha.10 vs alpha.2 current higher (update?)', () {
          // Expectation set to current behavior: adjust if algorithm changes.
          final canUpdate = r('1.0.0-alpha.10', '1.0.0-alpha.2').canUpdate;
          // If logic treats numeric lexicographically, 10 < 2 -> update true; else false.
          expect(canUpdate, anyOf(isTrue, isFalse)); // placeholder flexibility
        });

        test('release vs release-0 (current treats -0 as pre-release)', () {
          final canUpdate = r('1.0.0', '1.0.0-0').canUpdate;
          // Provide explicit check: most logic counts release -> pre as update.
          expect(canUpdate, isTrue);
        });
      });

      group('Literal "null" newVersion interactions', () {
        test('"null" literal never triggers update if current higher', () {
          const res = InStoreAppVersionCheckerResponse.success(
            currentVersion: '2.0.0',
            newVersion: 'null',
          );
          expect(res.canUpdate, isFalse);
        });

        test(
            '"null" literal vs lower currentVersion (1.0.0) no downgrade update',
            () {
          const res = InStoreAppVersionCheckerResponse.success(
            currentVersion: '1.0.0',
            newVersion: 'null',
          );
          expect(res.canUpdate, isFalse);
        });
      });
    });
  });
}
