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
  const appleResponse =
      '{"resultCount":1,"results":['
      '{"version":"2.0.0","trackViewUrl":"https://apps.apple.com/app/id123"}]}';
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
    String locale, {
    String body = appleResponse,
    int statusCode = 200,
    String? currentVersion,
    InStoreAppVersionCheckerAndroidStoreType androidStore =
        InStoreAppVersionCheckerAndroidStoreType.googlePlayStore,
  }) async {
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(body, statusCode);
    });
    addTearDown(client.close);
    return InStoreAppVersionChecker.instanceFor(httpClient: client).checkUpdate(
      InStoreAppVersionCheckerParams(
        locale: locale,
        currentVersion: currentVersion,
        androidStore: androidStore,
      ),
    );
  }

  group('Apple storefront locale', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    for (final entry in const <String, String>{
      'en-US': 'us',
      'en_AE': 'ae',
      'pt-BR': 'br',
      'zh-Hant-TW': 'tw',
      'ZH_hANS_cn': 'cn',
      'sr_Latn_RS': 'rs',
      'fil-PH': 'ph',
      ' EN_us ': 'us',
      'us': 'us',
      'AE': 'ae',
      ' ru ': 'ru',
      'de': 'de',
      'ar': 'ar',
    }.entries) {
      test('${entry.key} selects only storefront ${entry.value}', () async {
        final result = await check(entry.key);

        expect(result.isSuccess, isTrue);
        expect(result.currentVersion, '1.0.0');
        expect(result.newVersion, '2.0.0');
        expect(result.canUpdate, isTrue);
        expect(result.appURL, 'https://apps.apple.com/app/id123');
        expect(requests, hasLength(1));
        expect(requests.single.scheme, 'https');
        expect(requests.single.host, 'itunes.apple.com');
        expect(requests.single.path, '/${entry.value}/lookup');
        expect(requests.single.queryParameters['bundleId'], 'test.app');
        expect(
          int.tryParse(requests.single.queryParameters['_ts']!),
          isNotNull,
        );
      });
    }

    for (final locale in const <String>[
      '',
      ' ',
      'eng',
      'zh-Hant',
      'es-419',
      'en__US',
      'en-US-',
      'x-US',
      'en-US-TW',
      'en-US-u-ca-gregory',
      'en-US/lookup',
      'en-US\nextra',
    ]) {
      test('rejects "$locale" before making an Apple request', () async {
        final result = await check(locale);

        expect(result.isError, isTrue);
        expect(result.error, isA<FormatException>());
        expect(result.errorMessage, contains('Invalid locale "$locale"'));
        expect(result.errorMessage, contains('en-US'));
        expect(result.errorMessage, contains('two-letter storefront country'));
        expect(result.stackTrace, isNotNull);
        expect(result.currentVersion, '1.0.0');
        expect(result.newVersion, isNull);
        expect(result.appURL, isNull);
        expect(result.canUpdate, isFalse);
        expect(requests, isEmpty);
      });
    }

    test('invalid locale retains explicit currentVersion', () async {
      final result = await check('zh-Hant', currentVersion: '1.5.0');

      expect(result.isError, isTrue);
      expect(result.currentVersion, '1.5.0');
      expect(requests, isEmpty);
    });

    test('en HTTP 400 explains country selection without a fallback', () async {
      final result = await check('en', body: '', statusCode: 400);

      expect(result.isError, isTrue);
      expect(result.currentVersion, '1.0.0');
      expect(result.newVersion, isNull);
      expect(result.appURL, isNull);
      expect(result.canUpdate, isFalse);
      expect(result.stackTrace, isNotNull);
      expect(result.errorMessage, contains('HTTP 400'));
      expect(result.errorMessage, contains('locale: "en"'));
      expect(result.errorMessage, contains('storefront "en"'));
      expect(result.errorMessage, contains('country code'));
      expect(result.errorMessage, contains('en-US'));
      expect(result.errorMessage, isNot(contains('not found')));
      expect(requests, hasLength(1));
      expect(requests.single.path, '/en/lookup');
    });

    for (final statusCode in const <int>[400, 404, 429, 500]) {
      test('HTTP $statusCode reports the requested storefront', () async {
        final result = await check('en_AE', body: '', statusCode: statusCode);

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('HTTP $statusCode'));
        expect(result.errorMessage, contains('bundle ID "test.app"'));
        expect(result.errorMessage, contains('storefront "ae"'));
        expect(result.errorMessage, contains('locale: "en_AE"'));
        expect(result.errorMessage, isNot(contains('not found')));
        expect(
          result.errorMessage!.contains('Check the storefront country code'),
          statusCode == 400,
        );
        expect(result.canUpdate, isFalse);
        expect(requests, hasLength(1));
        expect(requests.single.path, '/ae/lookup');
      });
    }

    test(
      'empty results describe availability in the selected country',
      () async {
        final result = await check(
          'en-AE',
          body: '{"resultCount":0,"results":[]}',
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('App "test.app" was not found'));
        expect(result.errorMessage, contains('storefront "ae"'));
        expect(result.errorMessage, contains('locale: "en-AE"'));
        expect(
          result.errorMessage,
          contains('availability in this storefront'),
        );
        expect(result.errorMessage, isNot(contains('HTTP')));
        expect(result.newVersion, isNull);
        expect(result.appURL, isNull);
        expect(result.canUpdate, isFalse);
        expect(requests, hasLength(1));
        expect(requests.single.path, '/ae/lookup');
      },
    );
  });

  group('Google Play locale', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    for (final entry in const <String, String>{
      'en': 'en',
      'ru': 'ru',
      'en-US': 'en-US',
      'en_AE': 'en-AE',
      'pt-BR': 'pt-BR',
      'zh-Hant-TW': 'zh-Hant-TW',
      'ZH_hANS_cn': 'zh-Hans-CN',
      'sr_Latn_RS': 'sr-Latn-RS',
      'zh_hANT': 'zh-Hant',
      'es_419': 'es-419',
      ' EN_us ': 'en-US',
      'en-US-u-ca-gregory': 'en-US-u-ca-gregory',
    }.entries) {
      test('${entry.key} preserves language, script, and region', () async {
        final result = await check(entry.key, body: ',[[["2.0.0"]],');

        expect(result.isSuccess, isTrue);
        expect(result.canUpdate, isTrue);
        expect(requests, hasLength(1));
        expect(requests.single.host, 'play.google.com');
        expect(requests.single.path, '/store/apps/details');
        expect(requests.single.queryParameters['hl'], entry.value);
        expect(requests.single.queryParameters['id'], 'test.app');
        expect(result.appURL, requests.single.toString());
      });
    }
  });

  test('ApkPure continues to ignore locale', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final result = await check(
      'not/a/locale',
      androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
      body: '''
<div class="details-sdk"><span itemprop="version">2.0.0</span>for Android</div>
''',
    );

    expect(result.isSuccess, isTrue);
    expect(result.canUpdate, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.host, 'apkpure.com');
    expect(requests.single.path, '/test.app/test.app');
    expect(requests.single.queryParameters, isEmpty);
  });
}
