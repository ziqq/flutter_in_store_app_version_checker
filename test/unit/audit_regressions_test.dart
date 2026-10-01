import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../util/store_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );
  var metadataCalls = 0;
  var nativeCalls = 0;
  var metadataFails = false;
  late Completer<Object?> nativeResult;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    metadataCalls = 0;
    nativeCalls = 0;
    metadataFails = false;
    nativeResult = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAppMetadata') {
            metadataCalls++;
            if (metadataFails) throw StateError('metadata unavailable');
            return <String, Object?>{
              'packageName': 'installed.app',
              'version': '1.0.0',
            };
          }
          if (call.method == 'checkAppGalleryUpdate') {
            nativeCalls++;
            return nativeResult.future;
          }
          throw StateError('Unexpected method: ${call.method}');
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  InStoreAppVersionChecker checker(MockClient client) {
    addTearDown(client.close);
    return InStoreAppVersionChecker.instanceFor(httpClient: client);
  }

  const nativeParams = InStoreAppVersionCheckerParams(
    locale: 'ru-RU',
    androidStore: InStoreAppVersionCheckerAndroidStoreType.appGalleryNative,
  );
  Map<String, Object?> nativeListing() => <String, Object?>{
    'packageName': 'installed.app',
    'storeID': 'C107631977',
    'version': '2.0.0',
  };
  MockClient noHTTP() => MockClient(
    (_) async => throw StateError('Native mode must not use HTTP'),
  );

  group('release precedence', () {
    for (final pre in ['dev.1', 'alpha', 'beta.10', 'rc.1']) {
      test('$pre upgrades to release, not the reverse', () {
        expect(
          InStoreAppVersionCheckerResponse.success(
            currentVersion: '3.1.0-$pre',
            newVersion: '3.1.0',
          ).canUpdate,
          isTrue,
        );
        expect(
          InStoreAppVersionCheckerResponse.success(
            currentVersion: '3.1.0',
            newVersion: '3.1.0-$pre',
          ).canUpdate,
          isFalse,
        );
      });
    }
    test('core versions still take precedence over release status', () {
      const lowerRelease = InStoreAppVersionCheckerResponse.success(
        currentVersion: '3.1.1-dev.1',
        newVersion: '3.1.0',
      );
      const higherPre = InStoreAppVersionCheckerResponse.success(
        currentVersion: '3.1.0',
        newVersion: '3.1.1-dev.1',
      );
      expect(lowerRelease.canUpdate, isFalse);
      expect(higherPre.canUpdate, isTrue);
    });
  });

  group('response equality', () {
    test('success to error notifies ValueNotifier with identical versions', () {
      const success = InStoreAppVersionCheckerResponse.success(
        currentVersion: '1.0.0',
      );
      const error = InStoreAppVersionCheckerResponse.error(
        currentVersion: '1.0.0',
        errorMessage: 'lookup failed',
      );
      final notifier = ValueNotifier(success);
      addTearDown(notifier.dispose);
      var notifications = 0;
      notifier
        ..addListener(() => notifications++)
        ..value = error;
      expect(notifications, 1);
      expect(notifier.value.isError, isTrue);
      expect(success, isNot(equals(error)));
      expect(<InStoreAppVersionCheckerResponse>{success, error}, hasLength(2));
    });

    test(
      'equal errors have equal hashes regardless of diagnostic identity',
      () {
        final first = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          errorMessage: 'lookup failed',
          error: StateError('first'),
          stackTrace: StackTrace.fromString('first'),
        );
        final second = InStoreAppVersionCheckerResponse.error(
          currentVersion: '1.0.0',
          errorMessage: 'lookup failed',
          error: StateError('second'),
          stackTrace: StackTrace.fromString('second'),
        );
        expect(first, equals(second));
        expect(first.hashCode, second.hashCode);
      },
    );

    test('comparison with unrelated objects returns false', () {
      const Object response = InStoreAppVersionCheckerResponse.success(
        currentVersion: '1.0.0',
      );
      final other = Object();
      expect(response == other, isFalse);
      expect(response, equals(response));
    });
  });

  group('metadata resolution', () {
    for (final store in InStoreAppVersionCheckerAndroidStoreType.values.where(
      (store) =>
          store != InStoreAppVersionCheckerAndroidStoreType.appGalleryNative,
    )) {
      test('$store skips metadata when both overrides are supplied', () async {
        metadataFails = true;
        final client = MockClient((request) async {
          final body = switch (store) {
            InStoreAppVersionCheckerAndroidStoreType.googlePlayStore =>
              googlePlayListing('2.0.0', packageName: 'target.app'),
            InStoreAppVersionCheckerAndroidStoreType.apkPure =>
              '<div class="details-sdk"><span itemprop="version">'
                  ' 2.0.0</span>for Android</div>',
            InStoreAppVersionCheckerAndroidStoreType.ruStore =>
              '<script type="application/ld+json">'
                  ' {"@type":"SoftwareApplication","softwareVersion":"2.0.0"} '
                  ' </script>',
            InStoreAppVersionCheckerAndroidStoreType.appGallery =>
              request.method == 'POST'
                  ? jsonEncode('token')
                  : jsonEncode(<String, Object?>{
                      'rtnCode': 0,
                      'listing': <String, Object?>{
                        'appid': 'C107631977',
                        'package': 'target.app',
                        'versionName': '2.0.0',
                      },
                    }),
            InStoreAppVersionCheckerAndroidStoreType.appGalleryNative =>
              throw StateError('Native mode is not an HTTP store'),
          };
          return http.Response(body, 200);
        });
        final response = await checker(client).checkUpdate(
          InStoreAppVersionCheckerParams(
            locale: 'ru-RU',
            packageName: 'target.app',
            currentVersion: '1.0.0',
            storeID: 'C107631977',
            androidStore: store,
          ),
        );
        expect(response.isSuccess, isTrue, reason: response.errorMessage);
        expect(response.canUpdate, isTrue);
        expect(metadataCalls, 0);
      });
    }

    test('Apple skips metadata with both overrides', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      metadataFails = true;
      final client = MockClient((request) async {
        expect(request.url.queryParameters['bundleId'], 'target.app');
        return http.Response(
          '{"results":[{"bundleId":"target.app","version":"2.0.0"}]}',
          200,
        );
      });
      final response = await checker(client).checkUpdate(
        const InStoreAppVersionCheckerParams(
          locale: 'en-US',
          packageName: 'target.app',
          currentVersion: '1.0.0',
        ),
      );
      expect(response.isSuccess, isTrue);
      expect(metadataCalls, 0);
    });

    for (final params in [
      const InStoreAppVersionCheckerParams(locale: 'en-US'),
      const InStoreAppVersionCheckerParams(
        locale: 'en-US',
        packageName: 'target.app',
      ),
      const InStoreAppVersionCheckerParams(
        locale: 'en-US',
        currentVersion: '0.9.0',
      ),
    ]) {
      test(
        'partial overrides still propagate metadata errors: $params',
        () async {
          metadataFails = true;
          final response = await checker(noHTTP()).checkUpdate(params);
          expect(response.isError, isTrue);
          expect(response.errorMessage, contains('metadata unavailable'));
          expect(metadataCalls, 1);
        },
      );
    }

    test('native mode still reads metadata with both overrides', () async {
      final response = await checker(noHTTP()).checkUpdate(
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          packageName: 'target.app',
          currentVersion: '0.9.0',
          androidStore:
              InStoreAppVersionCheckerAndroidStoreType.appGalleryNative,
        ),
      );
      expect(response.isError, isTrue);
      expect(response.error, isA<ArgumentError>());
      expect(response.currentVersion, '1.0.0');
      expect(metadataCalls, 1);
      expect(nativeCalls, 0);
    });
  });

  group('bounded checks', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('$platform returns HTTP timeout errors', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final pending = Completer<http.Response>();
        final client = MockClient((_) => pending.future);
        final future = checker(client).checkUpdate(
          const InStoreAppVersionCheckerParams(
            locale: 'en-US',
            packageName: 'target.app',
            currentVersion: '1.0.0',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 15));
        final response = await future;
        expect(response.isError, isTrue);
        expect(response.error, isA<TimeoutException>());
        expect(response.currentVersion, '1.0.0');
        expect(response.canUpdate, isFalse);
        pending.complete(http.Response('late response', 200));
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('native calls share success and the next check starts fresh', (
      tester,
    ) async {
      nativeResult = Completer<Object?>();
      final first = checker(noHTTP()).checkUpdate(nativeParams);
      final second = checker(noHTTP()).checkUpdate(nativeParams);
      await tester.pump();
      expect(nativeCalls, 1);
      nativeResult.complete(nativeListing());
      await tester.pump();
      expect((await first).canUpdate, isTrue);
      expect((await second).canUpdate, isTrue);
      nativeResult = Completer<Object?>();
      final next = checker(noHTTP()).checkUpdate(nativeParams);
      await tester.pump();
      expect(nativeCalls, 2);
      nativeResult.complete(nativeListing());
      await tester.pump();
      expect((await next).isSuccess, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('native failures are shared and allow retry', (tester) async {
      nativeResult = Completer<Object?>();
      final first = checker(noHTTP()).checkUpdate(nativeParams);
      final second = checker(noHTTP()).checkUpdate(nativeParams);
      await tester.pump();
      expect(nativeCalls, 1);
      nativeResult.completeError(
        PlatformException(code: 'app_gallery_update_failed'),
      );
      await tester.pump();
      expect((await first).isError, isTrue);
      expect((await second).isError, isTrue);
      nativeResult = Completer<Object?>();
      final next = checker(noHTTP()).checkUpdate(nativeParams);
      await tester.pump();
      expect(nativeCalls, 2);
      nativeResult.complete(nativeListing());
      await tester.pump();
      expect((await next).isSuccess, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'native bridge timeout clears shared state and ignores late data',
      (tester) async {
        nativeResult = Completer<Object?>();
        final first = checker(noHTTP()).checkUpdate(nativeParams);
        final second = checker(noHTTP()).checkUpdate(nativeParams);
        await tester.pump();
        final oldResult = nativeResult;
        await tester.pump(const Duration(seconds: 20));
        expect((await first).error, isA<TimeoutException>());
        expect((await second).error, isA<TimeoutException>());
        expect(nativeCalls, 1);
        nativeResult = Completer<Object?>();
        final next = checker(noHTTP()).checkUpdate(nativeParams);
        await tester.pump();
        expect(nativeCalls, 2);
        oldResult.complete(nativeListing());
        await tester.pump();
        nativeResult.complete(nativeListing());
        await tester.pump();
        expect((await next).isSuccess, isTrue);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
