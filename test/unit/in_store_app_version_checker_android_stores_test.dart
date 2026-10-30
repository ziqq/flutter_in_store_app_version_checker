import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'github.com/ziqq/instoreappversionchecker/app_metadata',
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getAppMetadata':
              return <String, Object?>{
                'packageName': 'test.app',
                'version': '1.0.0',
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<InStoreAppVersionCheckerResponse> check(
    MockClient client,
    InStoreAppVersionCheckerParams params,
  ) {
    addTearDown(client.close);
    return InStoreAppVersionChecker.instanceFor(
      httpClient: client,
    ).checkUpdate(params);
  }

  String ruStorePage({Object? type = 'SoftwareApplication', String? version}) =>
      '<script type="application/ld+json">'
      '${jsonEncode(<String, Object?>{
        '@context': 'https://schema.org',
        '@graph': <Object?>[
          <String, Object?>{'@type': type, if (version != null) 'softwareVersion': version},
        ],
      })}'
      '</script>';

  String appGalleryDetail({
    Object? resultCode = 0,
    String storeID = 'C107631977',
    String? packageName = 'test.app',
    Object? version = '2.0.0',
  }) => jsonEncode(<String, Object?>{
    'rtnCode': resultCode,
    'layoutData': <Object?>[
      <String, Object?>{
        'layoutName': 'detailhiddencard',
        'dataList': <Object?>[
          <String, Object?>{
            'appid': storeID,
            'package': packageName,
            'versionName': version,
          },
        ],
      },
    ],
  });

  MockClient appGalleryClient(
    String detail, {
    String interfaceCode = 'interface-code',
    List<http.Request>? requests,
  }) => MockClient((request) async {
    requests?.add(request);
    if (request.method == 'POST') {
      return http.Response(jsonEncode(interfaceCode), 200);
    }
    return http.Response(detail, 200);
  });

  group('RuStore', () {
    test('reads SoftwareApplication version from JSON-LD', () async {
      late http.Request request;
      final client = MockClient((value) async {
        request = value;
        return http.Response(ruStorePage(version: '38.3.0'), 200);
      });

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          packageName: 'ru.beautybox.twa',
          currentVersion: '38.2.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '38.3.0');
      expect(result.canUpdate, isTrue);
      expect(
        result.appURL,
        'https://www.rustore.ru/catalog/app/ru.beautybox.twa',
      );
      expect(request.method, 'GET');
      expect(request.url.host, 'www.rustore.ru');
      expect(request.url.path, '/catalog/app/ru.beautybox.twa');
    });

    test('accepts a list-valued JSON-LD type', () async {
      final client = MockClient(
        (_) async => http.Response(
          '<script type="application/ld+json">not-json</script>'
          '${ruStorePage(type: <String>['Thing', 'SoftwareApplication'], version: '1.0.0')}',
          200,
        ),
      );

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '1.0.0');
    });

    test('returns an error for non-200 responses', () async {
      final client = MockClient((_) async => http.Response('blocked', 404));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('HTTP 404'));
      expect(result.canUpdate, isFalse);
    });

    test('returns an error when JSON-LD has no version', () async {
      final client = MockClient((_) async => http.Response(ruStorePage(), 200));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('softwareVersion'));
    });

    test('returns malformed JSON-LD errors', () async {
      final client = MockClient(
        (_) async => http.Response(
          '<script type="application/ld+json">{invalid</script>',
          200,
        ),
      );

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, isA<FormatException>());
    });

    test('returns request exceptions', () async {
      final client = MockClient((_) async => throw StateError('ru boom'));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('ru boom'));
    });
  });

  group('AppGallery web', () {
    test('checks an arbitrary listing by storeID', () async {
      final requests = <http.Request>[];
      final client = appGalleryClient(
        appGalleryDetail(resultCode: 0.0),
        requests: requests,
      );

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'zh-Hant-TW',
          packageName: 'test.app',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.newVersion, '2.0.0');
      expect(result.appURL, 'https://appgallery.huawei.com/#/app/C107631977');
      expect(result.canUpdate, isTrue);
      expect(requests, hasLength(2));
      expect(requests.first.method, 'POST');
      expect(requests.first.url.path, '/edge/webedge/getInterfaceCode');
      expect(requests.last.method, 'GET');
      expect(requests.last.url.queryParameters['uri'], 'app|C107631977');
      expect(requests.last.url.queryParameters['locale'], 'zh_Hant_TW');
      expect(
        requests.last.headers['Identity-Id'],
        requests.first.headers['Identity-Id'],
      );
      expect(
        requests.last.headers['Interface-Code'],
        startsWith('interface-code_'),
      );
    });

    test('accepts a string result code', () async {
      final client = appGalleryClient(appGalleryDetail(resultCode: '0'));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue);
    });

    test('refreshes the interface code once for result code 1002', () async {
      final requests = <http.Request>[];
      var postCount = 0;
      var getCount = 0;
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          postCount++;
          return http.Response(jsonEncode('token-$postCount'), 200);
        }
        getCount++;
        return http.Response(
          getCount == 1
              ? appGalleryDetail(resultCode: 1002)
              : appGalleryDetail(),
          200,
        );
      });

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          packageName: 'test.app',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(postCount, 2);
      expect(getCount, 2);
      expect(requests, hasLength(4));
      expect(requests.last.headers['Interface-Code'], startsWith('token-2_'));
    });

    test('requires a C-prefixed numeric storeID', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('', 500);
      });

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: '107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, isA<FormatException>());
      expect(result.errorMessage, contains('storeID'));
      expect(requests, 0);
    });

    test('rejects a package mismatch', () async {
      final client = appGalleryClient(
        appGalleryDetail(packageName: 'another.app'),
      );

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          packageName: 'test.app',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('another.app'));
      expect(result.errorMessage, contains('test.app'));
    });

    test('requires a version in the matching listing', () async {
      final client = appGalleryClient(appGalleryDetail(version: ''));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('does not contain a version'));
    });

    test('requires a package in the matching listing', () async {
      final client = appGalleryClient(appGalleryDetail(packageName: null));

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('does not contain a package'));
    });

    test('returns an error when the listing is absent', () async {
      final client = appGalleryClient(
        jsonEncode(<String, Object?>{'rtnCode': 0, 'layoutData': <Object?>[]}),
      );

      final result = await check(
        client,
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: 'C107631977',
          currentVersion: '1.0.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('does not contain listing'));
    });

    test('returns non-zero and fractional result codes as errors', () async {
      for (final code in <Object?>[42, 0.5, null]) {
        final client = appGalleryClient(appGalleryDetail(resultCode: code));
        final result = await check(
          client,
          const InStoreAppVersionCheckerParams(
            locale: 'ru-RU',
            storeID: 'C107631977',
            currentVersion: '1.0.0',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
          ),
        );

        expect(result.isError, isTrue, reason: 'result code: $code');
        expect(result.errorMessage, contains('result code'));
      }
    });

    test('returns interface-code HTTP and format errors', () async {
      final clients = <MockClient>[
        MockClient((_) async => http.Response('denied', 503)),
        MockClient((_) async => http.Response('{}', 200)),
      ];

      for (final client in clients) {
        final result = await check(
          client,
          const InStoreAppVersionCheckerParams(
            locale: 'ru-RU',
            storeID: 'C107631977',
            currentVersion: '1.0.0',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
          ),
        );
        expect(result.isError, isTrue);
      }
    });

    test('returns tab-detail HTTP and format errors', () async {
      for (final response in <http.Response>[
        http.Response('denied', 503),
        http.Response('[]', 200),
      ]) {
        final client = MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(jsonEncode('token'), 200);
          }
          return response;
        });
        final result = await check(
          client,
          const InStoreAppVersionCheckerParams(
            locale: 'ru-RU',
            storeID: 'C107631977',
            currentVersion: '1.0.0',
            androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
          ),
        );
        expect(result.isError, isTrue);
      }
    });
  });

  group('AppGallery by package name', () {
    test('finds the installed application without storeID', () async {
      final requests = <http.Request>[];

      final result = await check(
        appGalleryClient(appGalleryDetail(), requests: requests),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.currentVersion, '1.0.0');
      expect(result.newVersion, '2.0.0');
      expect(result.canUpdate, isTrue);
      expect(result.appURL, 'https://appgallery.huawei.com/#/app/C107631977');
      expect(requests.last.url.queryParameters['uri'], 'package|test.app');
    });

    test('finds an overridden package name', () async {
      final requests = <http.Request>[];

      final result = await check(
        appGalleryClient(
          appGalleryDetail(packageName: 'ru.beautybox.twa', version: '38.3.0'),
          requests: requests,
        ),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          packageName: 'ru.beautybox.twa',
          currentVersion: '38.2.0',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.newVersion, '38.3.0');
      expect(result.canUpdate, isTrue);
      expect(result.appURL, 'https://appgallery.huawei.com/#/app/C107631977');
      expect(
        requests.last.url.queryParameters['uri'],
        'package|ru.beautybox.twa',
      );
    });

    test('treats a blank storeID as absent', () async {
      final requests = <http.Request>[];

      final result = await check(
        appGalleryClient(appGalleryDetail(), requests: requests),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          storeID: ' ',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(requests.last.url.queryParameters['uri'], 'package|test.app');
    });

    test('deprecated appGalleryNative uses the same lookup', () async {
      final requests = <http.Request>[];

      final result = await check(
        appGalleryClient(appGalleryDetail(), requests: requests),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore:
              // ignore: deprecated_member_use_from_same_package
              InStoreAppVersionCheckerAndroidStoreType.appGalleryNative,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.newVersion, '2.0.0');
      expect(result.appURL, 'https://appgallery.huawei.com/#/app/C107631977');
      expect(requests.last.url.queryParameters['uri'], 'package|test.app');
    });

    test('ignores listings of other packages', () async {
      final result = await check(
        appGalleryClient(appGalleryDetail(packageName: 'another.app')),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(
        result.errorMessage,
        contains('does not contain listing of package "test.app"'),
      );
    });

    test('returns an error when the application is not published', () async {
      final result = await check(
        appGalleryClient(
          jsonEncode(<String, Object?>{
            'rtnCode': 0,
            'layoutData': <Object?>[],
          }),
        ),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, isA<FormatException>());
      expect(
        result.errorMessage,
        contains('does not contain listing of package "test.app"'),
      );
    });

    test('requires a valid App ID in the listing', () async {
      final result = await check(
        appGalleryClient(appGalleryDetail(storeID: '107631977')),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('valid App ID'));
    });

    test('names the package in result code errors', () async {
      final result = await check(
        appGalleryClient(appGalleryDetail(resultCode: 1)),
        const InStoreAppVersionCheckerParams(
          locale: 'ru-RU',
          androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
        ),
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('result code 1'));
      expect(result.errorMessage, contains('package "test.app"'));
    });
  });
}
