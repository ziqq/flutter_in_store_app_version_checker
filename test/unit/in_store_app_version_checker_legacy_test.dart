/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 11 December 2023
 */

// ignore_for_file: avoid_positional_boolean_parameters, deprecated_member_use_from_same_package

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../util/mocks.dart';

void main() {
  group('InStoreAppVersionCheckerLegacy - ', () {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    late MockClient mockHttpClient;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (methodCall) async {
          if (methodCall.method == 'getDeviceInfo') {
            if (defaultTargetPlatform == TargetPlatform.android) {
              return fakeAndroidDeviceInfo;
            } else if (defaultTargetPlatform == TargetPlatform.iOS) {
              return iosDeviceInfoMap;
            }
            return iosDeviceInfoMap;
          }
          return iosDeviceInfoMap;
        },
      );
      mockHttpClient = MockClient();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Init with default http.Client() produces error (no store)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final checker = InStoreAppVersionChecker(
        currentVersion: '1.0.0',
        appId: 'com.example.app',
      );
      final result = await checker.checkUpdate();
      expect(result.errorMessage, isNotNull);
      expect(result.canUpdate, isFalse);
    });

    group('Unsupported platform - ', () {
      test('macOS -> error result', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final result = await checker.checkUpdate();
        expect(result.newVersion, isNull);
        expect(result.appURL, null);
        expect(
          result.errorMessage,
          'This platform is not yet supported by this package. We support iOS or Android platrforms.',
        );
        expect(result.canUpdate, isFalse);
      });
    });

    group('Apple Store - ', () {
      test('Success parses version and url', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        const version = '1.2.3';
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"$version","trackViewUrl":"https://apps.apple.com/app/id1"}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, version);
        expect(res.appURL, isNotNull);
        expect(res.canUpdate, isTrue);
      });

      test('Missing trackViewUrl -> appURL "null" (current buggy behavior)',
          () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"2.0.0"}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.9.9',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '2.0.0');
        expect(res.appURL, 'null'); // библиотека возвращает строку 'null'
        expect(res.canUpdate, isTrue);
      });

      test('Empty results', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"resultCount":0,"results":[]}', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.errorMessage, contains("Can't find an app"));
        expect(res.canUpdate, isFalse);
      });

      test('Status != 200', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('x', 404),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.errorMessage, isNotNull);
        expect(res.canUpdate, isFalse);
      });

      test('Thrown exception surfaces', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenThrow('Fail');
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.errorMessage, 'Fail');
        expect(res.canUpdate, isFalse);
      });

      test('Malformed JSON', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"resultCount":1,"results":[}', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.errorMessage, isNotNull);
        expect(res.canUpdate, isFalse);
      });
    });

    group('Google Play / ApkPure', () {
      test('Google Play primary regex', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(',[[["3.2.1"]],', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '3.2.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '3.2.1');
        expect(res.canUpdate, isTrue);
      });

      test('Google Play secondary regex', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('"5.4.3"', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '5.4.2',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '5.4.3');
        expect(res.canUpdate, isTrue);
      });

      test('Fallback API success', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'play', 'play.google.com'),
        ))).thenAnswer((_) async => http.Response('html', 200));
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'api', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('{"version":"9.9.9"}', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '9.9.8',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '9.9.9');
        expect(res.canUpdate, isTrue);
      });

      test('Fallback API missing version', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('html', 200),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'api', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('{"name":"App"}', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.canUpdate, isFalse);
        expect(res.errorMessage, isNotNull);
      });

      test('Fallback API error status', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('html', 200),
        );
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'api', 'api.playstoreapi.com'),
        ))).thenAnswer(
          (_) async => http.Response('failure', 500),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '5.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.canUpdate, isFalse);
        expect(res.errorMessage, contains('PlayStoreApi error: 500'));
      });

      test('ApkPure success', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '<div class="details-sdk"><span itemprop="version">4.5.6</span>for Android</div>',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '4.5.5',
          appId: 'com.example.app',
          androidStore: AndroidStore.apkPure,
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '4.5.6');
        expect(res.canUpdate, isTrue);
      });

      test('ApkPure parse fail', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('<html></html>', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          androidStore: AndroidStore.apkPure,
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.canUpdate, isFalse);
        expect(res.errorMessage, isNotNull);
      });

      test('ApkPure non-200', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('x', 404),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          androidStore: AndroidStore.apkPure,
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.canUpdate, isFalse);
        expect(
          res.errorMessage,
          "Can't find an app in the ApkPure Store with the id: com.example.app",
        );
      });
    });

    group('canUpdate numeric core comparisons', () {
      InStoreAppVersionCheckerResult r(String a, String? b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);

      test('Equal versions',
          () => expect(r('1.2.3', '1.2.3').canUpdate, isFalse));
      test('Patch increase',
          () => expect(r('1.2.3', '1.2.4').canUpdate, isTrue));
      test('Minor increase',
          () => expect(r('1.2.3', '1.3.0').canUpdate, isTrue));
      test('Major increase',
          () => expect(r('1.2.3', '2.0.0').canUpdate, isTrue));
      test('Patch downgrade',
          () => expect(r('1.2.3', '1.2.2').canUpdate, isFalse));
      test('Length diff trailing zero',
          () => expect(r('1.2', '1.2.0').canUpdate, isFalse));
      test('Extra segment higher',
          () => expect(r('1.2.3', '1.2.3.1').canUpdate, isTrue));
      test('Current longer higher',
          () => expect(r('1.2.3.4', '1.2.3').canUpdate, isFalse));
      test('Sanitized non-numeric prefix',
          () => expect(r('v1.2.3 ', '1.2.4').canUpdate, isTrue));
      test('Build metadata ignored',
          () => expect(r('1.0.0+42', '1.0.0+99').canUpdate, isFalse));
      test('Build metadata with higher patch',
          () => expect(r('1.0.0+42', '1.0.1+1').canUpdate, isTrue));
    });

    group('Pre-release lexicographic (current vs new)', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);

      test('pre -> release (no update)',
          () => expect(r('1.0.0-beta', '1.0.0').canUpdate, isFalse));
      test('release -> pre (update)',
          () => expect(r('1.0.0', '1.0.0-beta').canUpdate, isTrue));
      test('alpha -> beta (update)',
          () => expect(r('1.0.0-alpha', '1.0.0-beta').canUpdate, isTrue));
      test('beta -> alpha (no update)',
          () => expect(r('1.0.0-beta', '1.0.0-alpha').canUpdate, isFalse));
      test('beta.2 -> beta.10 (no update)',
          () => expect(r('1.0.0-beta.2', '1.0.0-beta.10').canUpdate, isFalse));
      test('beta.10 -> beta.2 (update)',
          () => expect(r('1.0.0-beta.10', '1.0.0-beta.2').canUpdate, isTrue));
      test('alpha.10 -> alpha.2 (update)',
          () => expect(r('1.0.0-alpha.10', '1.0.0-alpha.2').canUpdate, isTrue));
      test(
          'alpha.2 -> alpha.10 (no update)',
          () =>
              expect(r('1.0.0-alpha.2', '1.0.0-alpha.10').canUpdate, isFalse));
      test(
          'alpha-beta -> alpha-gamma (update)',
          () => expect(
              r('1.0.0-alpha-beta', '1.0.0-alpha-gamma').canUpdate, isTrue));
      test(
          'alpha-gamma -> alpha-beta (no update)',
          () => expect(
              r('1.0.0-alpha-gamma', '1.0.0-alpha-beta').canUpdate, isFalse));
      test('alpha-1 -> alpha-2 (update)',
          () => expect(r('1.0.0-alpha-1', '1.0.0-alpha-2').canUpdate, isTrue));
      test('alpha-2 -> alpha-1 (no update)',
          () => expect(r('1.0.0-alpha-2', '1.0.0-alpha-1').canUpdate, isFalse));
      test('release -> same core -0 (update)',
          () => expect(r('1.0.0', '1.0.0-0').canUpdate, isTrue));
      test('pre -> release + metadata (no update)',
          () => expect(r('1.0.0-beta', '1.0.0+build').canUpdate, isFalse));
      test('rc -> release (no update)',
          () => expect(r('1.0.0-rc', '1.0.0').canUpdate, isFalse));
      test('release -> rc (update)',
          () => expect(r('1.0.0', '1.0.0-rc').canUpdate, isTrue));
      test('Beta -> beta (update)',
          () => expect(r('1.0.0-Beta', '1.0.0-beta').canUpdate, isTrue));
      test('beta -> Beta (no update)',
          () => expect(r('1.0.0-beta', '1.0.0-Beta').canUpdate, isFalse));
      test('Trailing dash current (no update)',
          () => expect(r('1.0.0-', '1.0.0').canUpdate, isFalse));
      test('Trailing dash new (update)',
          () => expect(r('1.0.0', '1.0.0-').canUpdate, isTrue));
      test('Empty pre vs alpha (update)',
          () => expect(r('1.0.0-', '1.0.0-alpha').canUpdate, isTrue));
      test('alpha vs empty pre (no update)',
          () => expect(r('1.0.0-alpha', '1.0.0-').canUpdate, isFalse));
      test('alpha-10 -> alpha-2 (update)',
          () => expect(r('1.0.0-alpha-10', '1.0.0-alpha-2').canUpdate, isTrue));
      test(
          'alpha-2 -> alpha-10 (no update)',
          () =>
              expect(r('1.0.0-alpha-2', '1.0.0-alpha-10').canUpdate, isFalse));
      test('Numeric 2 -> 10 (no update)',
          () => expect(r('1.0.0-2', '1.0.0-10').canUpdate, isFalse));
      test('Numeric 10 -> 2 (update)',
          () => expect(r('1.0.0-10', '1.0.0-2').canUpdate, isTrue));
      test('a2 -> a10 (no update)',
          () => expect(r('1.0.0-a2', '1.0.0-a10').canUpdate, isFalse));
      test('a10 -> a2 (update)',
          () => expect(r('1.0.0-a10', '1.0.0-a2').canUpdate, isTrue));
    });

    group('Normalization & sanitization', () {
      InStoreAppVersionCheckerResult r(String a, String? b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('Whitespace trimmed',
          () => expect(r(' 1.2.3 ', ' 1.2.4 ').canUpdate, isTrue));
      test('Non-digit stripped prefix',
          () => expect(r('version1.2.3', '1.2.4').canUpdate, isTrue));
      test('All non-numeric current treated as zeros',
          () => expect(r('abc', '1.0.0').canUpdate, isTrue));
      test('All non-numeric new -> no update',
          () => expect(r('1.0.0', 'xyz').canUpdate, isFalse));
      test('Mixed alphanumeric "x" -> numeric higher',
          () => expect(r('1.x.0', '1.1.0').canUpdate, isTrue));
      test('Long chain increment last',
          () => expect(r('1.1.1.1.1.1.1', '1.1.1.1.1.1.2').canUpdate, isTrue));
      test('Downgrade last',
          () => expect(r('1.1.1.1.1.1.2', '1.1.1.1.1.1.1').canUpdate, isFalse));
      test(
          'Null newVersion', () => expect(r('2.3.4', null).canUpdate, isFalse));
      test('Large jump first segment',
          () => expect(r('1.2.3', '10.0.0').canUpdate, isTrue));
      test('Large downgrade first segment',
          () => expect(r('10.0.0', '1.2.3').canUpdate, isFalse));
      test('Leading zeros equal',
          () => expect(r('01.002.003', '1.2.3').canUpdate, isFalse));
      test('Leading zeros -> higher patch',
          () => expect(r('01.002.003', '1.2.4').canUpdate, isTrue));
    });

    group('Single segment', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('1 -> 2 update', () => expect(r('1', '2').canUpdate, isTrue));
      test('2 -> 1 no update', () => expect(r('2', '1').canUpdate, isFalse));
      test('1-alpha -> 1 (no update)',
          () => expect(r('1-alpha', '1').canUpdate, isFalse));
      test('1 -> 1-alpha (update)',
          () => expect(r('1', '1-alpha').canUpdate, isTrue));
      test('1-alpha -> 1-beta (update)',
          () => expect(r('1-alpha', '1-beta').canUpdate, isTrue));
      test('1-beta -> 1-alpha (no update)',
          () => expect(r('1-beta', '1-alpha').canUpdate, isFalse));
    });

    group('Extreme numeric values', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('Huge major jump',
          () => expect(r('1.0.0', '1000.0.0').canUpdate, isTrue));
      test('Huge major downgrade',
          () => expect(r('1000.0.0', '1.0.0').canUpdate, isFalse));
      test('Huge trailing increase',
          () => expect(r('1.0.0.1', '1.0.0.999999').canUpdate, isTrue));
      test('Huge trailing downgrade',
          () => expect(r('1.0.0.999999', '1.0.0.1').canUpdate, isFalse));
    });

    group('Alphanumeric core segments treated as 0', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('Letter segment -> update when new numeric higher',
          () => expect(r('1.a.0', '1.1.0').canUpdate, isTrue));
      test('Numeric current vs alphanumeric new',
          () => expect(r('1.1.0', '1.a.0').canUpdate, isFalse));
      test('All alpha current -> numeric new',
          () => expect(r('x.y.z', '1.0.0').canUpdate, isTrue));
      test('Numeric current -> all alpha new',
          () => expect(r('1.0.0', 'x.y.z').canUpdate, isFalse));
    });

    group('Null / empty / literal null', () {
      InStoreAppVersionCheckerResult r(String a, String? b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('Literal "null" vs actual null', () {
        const a = InStoreAppVersionCheckerResult(currentVersion: '1.0.0');
        const b = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: 'null');
        expect(a.newVersion, isNull);
        expect(b.newVersion, 'null');
        expect(a.canUpdate, isFalse);
        expect(b.canUpdate, isFalse);
      });
      test('Empty newVersion', () {
        final res = r('1.0.0', '');
        expect(res.newVersion, '');
        expect(res.canUpdate, isFalse);
      });
      test('Whitespace newVersion', () {
        final res = r('2.0.0', '   ');
        expect(res.newVersion, '   ');
        expect(res.canUpdate, isFalse);
      });
      test('Empty current vs numeric new', () {
        final res = r('', '1.0.0');
        expect(res.canUpdate, isTrue);
      });
      test('Both empty', () {
        final res = r('', '');
        expect(res.canUpdate, isFalse);
      });
    });

    group('Unicode / symbols stripping', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('Cyrillic stripped',
          () => expect(r('v1.0.0пр', '1.0.1').canUpdate, isTrue));
      test('Chinese stripped',
          () => expect(r('版本2.0.0', '2.0.1').canUpdate, isTrue));
      test('Emoji stripped',
          () => expect(r('1.0.0🔥', '1.0.1').canUpdate, isTrue));
      test('Emoji only new',
          () => expect(r('1.0.0', '😀😀').canUpdate, isFalse));
    });

    group('Equality / hashCode', () {
      test('StackTrace ignored in equality', () {
        const a = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0');
        final b = InStoreAppVersionCheckerResult(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          stackTrace: StackTrace.current,
        );
        expect(a, equals(b));
      });
      test('Error message affects equality', () {
        const a = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0');
        const b = InStoreAppVersionCheckerResult(
          currentVersion: '1.0.0',
          newVersion: '1.1.0',
          errorMessage: 'err',
        );
        expect(a == b, isFalse);
      });
      test('AppURL difference', () {
        const a = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0', appURL: 'u1');
        const b = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0', appURL: 'u2');
        expect(a == b, isFalse);
      });
      test('Different newVersion same canUpdate not equal', () {
        const a = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.0.0');
        const b = InStoreAppVersionCheckerResult(currentVersion: '1.0.0');
        expect(a.canUpdate, isFalse);
        expect(b.canUpdate, isFalse);
        expect(a == b, isFalse);
      });
      test('hashCode differs', () {
        const a = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0');
        const b = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.2.0');
        expect(a.hashCode == b.hashCode, isFalse);
      });
    });

    group('toString formatting', () {
      test('Success formatting', () {
        const r = InStoreAppVersionCheckerResult(
          currentVersion: '1.2.3',
          newVersion: '1.2.4',
          appURL: 'https://x',
        );
        final s = r.toString();
        expect(s, contains('Current version: 1.2.3'));
        expect(s, contains('New version: 1.2.4'));
        expect(s, contains('App url: https://x'));
        expect(s, contains('Can update: true'));
      });
      test('Error & stackTrace included', () {
        final r = InStoreAppVersionCheckerResult(
          currentVersion: '1.0.0',
          newVersion: '1.0.0',
          errorMessage: 'fail',
          stackTrace: StackTrace.current,
        );
        final s = r.toString();
        expect(s, contains('Error: fail'));
        expect(s, contains('Stack trace:'));
      });
      test('Null newVersion visible', () {
        const r = InStoreAppVersionCheckerResult(currentVersion: '1.0.0');
        expect(r.toString(), contains('New version: null'));
      });
      test('No error/stack omits labels', () {
        const r = InStoreAppVersionCheckerResult(
            currentVersion: '1.0.0', newVersion: '1.1.0');
        final s = r.toString();
        expect(s, isNot(contains('Error:')));
        expect(s, isNot(contains('Stack trace:')));
      });
    });

    group('Segment length & trailing zeros', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('1.0 vs 1.0.0', () => expect(r('1.0', '1.0.0').canUpdate, isFalse));
      test('1.0.0 vs 1.0', () => expect(r('1.0.0', '1.0').canUpdate, isFalse));
      test('1.0.0 vs 1.0.0.1',
          () => expect(r('1.0.0', '1.0.0.1').canUpdate, isTrue));
      test('1.0.0.1 vs 1.0.0',
          () => expect(r('1.0.0.1', '1.0.0').canUpdate, isFalse));
    });

    group('Extreme jumps (repeat)', () {
      InStoreAppVersionCheckerResult r(String a, String b) =>
          InStoreAppVersionCheckerResult(currentVersion: a, newVersion: b);
      test('1.0.0 -> 100.0.0',
          () => expect(r('1.0.0', '100.0.0').canUpdate, isTrue));
      test('100.0.0 -> 1.0.0',
          () => expect(r('100.0.0', '1.0.0').canUpdate, isFalse));
    });

    // Additional groups documenting current bugs and edge cases
    group('Apple Store appURL null handling', () {
      test('Explicit trackViewUrl:null -> "null" string', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"3.1.0","trackViewUrl":null}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '3.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.appURL, 'null');
        expect(res.newVersion, '3.1.0');
        expect(res.canUpdate, isTrue);
      });

      test('Empty trackViewUrl string', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"4.0.0","trackViewUrl":""}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '3.9.9',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.appURL, '');
        expect(res.canUpdate, isTrue);
      });

      test('Whitespace trackViewUrl preserved', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"5.0.0","trackViewUrl":"   "}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '4.9.9',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.appURL, '   ');
        expect(res.canUpdate, isTrue);
      });

      test('Valid trackViewUrl', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"6.0.0","trackViewUrl":"https://apps.apple.com/app/id123"}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '5.9.9',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.appURL, startsWith('https://apps.apple.com/'));
        expect(res.canUpdate, isTrue);
      });

      test('resultCount=0 -> appURL null', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"resultCount":0,"results":[]}', 200),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.appURL, isNull);
        expect(res.canUpdate, isFalse);
      });
    });

    group('Literal "null" newVersion scenarios', () {
      test('"null" literal does not trigger update when same core', () {
        const res = InStoreAppVersionCheckerResult(
          currentVersion: '1.0.0',
          newVersion: 'null',
        );
        expect(res.canUpdate, isFalse);
        expect(res.newVersion, 'null');
      });

      test('"null" literal vs higher numeric (update)', () {
        const res = InStoreAppVersionCheckerResult(
          currentVersion: '1.0.0',
          newVersion: '1.0.1',
        );
        expect(res.canUpdate, isTrue);
      });

      test('"null" literal vs lower numeric (no update)', () {
        const res = InStoreAppVersionCheckerResult(
          currentVersion: '2.0.0',
          newVersion: 'null',
        );
        expect(res.canUpdate, isFalse);
      });
    });

    group('Apple Store version parsing robustness', () {
      test('Non-semver style version accepted', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"2024.12","trackViewUrl":"https://x"}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: '2024.11',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '2024.12');
        expect(res.canUpdate, isTrue);
      });

      test('Non-numeric prefix stripped for comparison', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"resultCount":1,"results":[{"version":"v1.0.1","trackViewUrl":"https://x"}]}',
            200,
          ),
        );
        final checker = InStoreAppVersionChecker(
          currentVersion: 'v1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, 'v1.0.1');
        expect(res.canUpdate, isTrue);
      });
    });

    group('Play Store fallback edge parsing', () {
      test('HTML no match + API missing version -> error', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'play', 'play.google.com'),
        ))).thenAnswer((_) async => http.Response('<html></html>', 200));
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'api', 'api.playstoreapi.com'),
        ))).thenAnswer((_) async => http.Response('{"other":"x"}', 200));
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.0.0',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, isNull);
        expect(res.errorMessage, isNotNull);
        expect(res.canUpdate, isFalse);
      });

      test('HTML 404 then API success version', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'play', 'play.google.com'),
        ))).thenAnswer((_) async => http.Response('nf', 404));
        when(mockHttpClient.get(argThat(
          isA<Uri>().having((u) => u.host, 'api', 'api.playstoreapi.com'),
        ))).thenAnswer((_) async => http.Response('{"version":"2.0.0"}', 200));
        final checker = InStoreAppVersionChecker(
          currentVersion: '1.9.9',
          appId: 'com.example.app',
          httpClient: mockHttpClient,
        );
        final res = await checker.checkUpdate();
        expect(res.newVersion, '2.0.0');
        expect(res.canUpdate, isTrue);
      });
    });
  });
}
