import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/src/util/app_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMetadata.fromPlatform - ', () {
    const channel = MethodChannel(
      'github.com/ziqq/instoreappversionchecker/app_metadata',
    );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('returns packageName and version from platform data', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getAppMetadata');
            return {'packageName': 'com.example.app', 'version': '2.3.4'};
          });

      final appMetadata = await AppMetadata.fromPlatform();

      expect(appMetadata.packageName, 'com.example.app');
      expect(appMetadata.version, '2.3.4');
    });

    test('coerces platform values to strings', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {'packageName': 123, 'version': 456},
          );

      final appMetadata = await AppMetadata.fromPlatform();

      expect(appMetadata.packageName, '123');
      expect(appMetadata.version, '456');
    });

    test('throws when packageName is missing', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => {'version': '2.3.4'});

      await expectLater(
        AppMetadata.fromPlatform(),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'invalid_package_info')
              .having(
                (e) => e.message,
                'message',
                contains('TargetPlatform.android'),
              ),
        ),
      );
    });

    test('throws when version is missing', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {'packageName': 'com.example.app'},
          );

      await expectLater(
        AppMetadata.fromPlatform(),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'invalid_package_info')
              .having(
                (e) => e.message,
                'message',
                contains('TargetPlatform.iOS'),
              ),
        ),
      );
    });
  });
}
