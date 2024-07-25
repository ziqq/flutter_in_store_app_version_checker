// Autor - <a.a.ustinoff@gmail.com> Anton Ustinoff, 11 December 2023

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../util/mocks.dart';

void main() => group(
    'Unit_tests -',
    () => group('InStoreAppVersionChecker', () {
          const channel =
              MethodChannel('dev.fluttercommunity.plus/package_info');
          late MockClient mockHttpClient;

          setUp(() {
            TestWidgetsFlutterBinding.ensureInitialized();

            // PackageInfo.setMockInitialValues(
            //   installerStore: 'installerStore',
            //   buildNumber: '2',
            //   version: '2.0.0',
            //   appName: 'appName',
            //   packageName: 'packageName',
            //   buildSignature: 'buildSignature',
            // );

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
          });

          test('Init with default `http.Client()`', () async {
            debugDefaultTargetPlatformOverride = TargetPlatform.android;

            final checker = InStoreAppVersionChecker(
              currentVersion: '1.0.0',
              appId: 'com.example.app',
            );

            final result = await checker.checkUpdate();

            expect(result.errorMessage, isNotNull);
            expect(result.canUpdate, isFalse);
          });

          group('Check is web -', () {
            test(
                'When called, should return <InStoreAppVersionCheckerResult> with error message',
                () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

              final checker = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result = await checker.checkUpdate();

              expect(
                result,
                const InStoreAppVersionCheckerResult(
                  '1.0.0',
                  null,
                  '',
                  'This platform is not yet supported by this package. We support iOS or Android platrforms.',
                ),
              );
            });
          });

          group('Apple Store -', () {
            test('Successful check for Apple Store', () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

              const vesion = '1.2.3';

              when(mockHttpClient.get(any)).thenAnswer(
                (_) async => http.Response(
                  '{"resultCount":1,"results":[{"version":"$vesion","trackViewUrl":"https://apps.apple.com/us/app/your-app-name/id123456789"}]}',
                  200,
                ),
              );

              final checker = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result = await checker.checkUpdate();

              expect(result.currentVersion, equals('1.0.0'));
              expect(result.newVersion, equals(vesion));
            });
            test('Successful check hashCode should be false', () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

              const vesion = '1.2.3';

              when(mockHttpClient.get(any)).thenAnswer(
                (_) async => http.Response(
                  '{"resultCount":1,"results":[{"version":"$vesion","trackViewUrl":"https://apps.apple.com/us/app/your-app-name/id123456789"}]}',
                  200,
                ),
              );

              final checker_1 = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final checker_2 = InStoreAppVersionChecker(
                currentVersion: '2.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result_1 = await checker_1.checkUpdate();
              final result_2 = await checker_2.checkUpdate();

              expect(result_1.hashCode == result_2.hashCode, isFalse);
            });
            test(
                'When results is empty, should get error response with error message as <String>',
                () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

              when(mockHttpClient.get(any)).thenAnswer(
                (_) async => http.Response(
                  '{"resultCount": 0,"results":[]}',
                  200,
                ),
              );

              final checker = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result = await checker.checkUpdate();

              expect(result.currentVersion, equals('1.0.0'));
              expect(
                result.errorMessage,
                "Can't find an app in the Apple Store with the id: com.example.app",
              );
              expect(result.newVersion, isNull);
              expect(result.canUpdate, isFalse);
            });
            test('Error response as <String> from Google Play Store', () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
              const errorMessage = "It's error";

              when(mockHttpClient.get(any)).thenThrow(errorMessage);

              final checker = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result = await checker.checkUpdate();

              expect(result.currentVersion, equals('1.0.0'));
              expect(result.errorMessage, errorMessage);
              expect(result.newVersion, isNull);
              expect(result.canUpdate, isFalse);
            });
            test('Error response from Apple Store', () async {
              debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

              when(mockHttpClient.get(any))
                  .thenAnswer((_) async => http.Response('Error', 404));

              final checker = InStoreAppVersionChecker(
                currentVersion: '1.0.0',
                appId: 'com.example.app',
              )..setHttpClient(mockHttpClient);

              final result = await checker.checkUpdate();

              expect(result.errorMessage, isNotNull);
            });
          });

          group('AndroidS tore -', () {
            group('Default -', () {
              test('Successful check for Google Play Store', () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;
                const vesion = '1.2.3';

                when(mockHttpClient.get(any)).thenAnswer(
                  (_) async => http.Response(',[[["$vesion"]],', 200),
                );

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.currentVersion, equals('1.0.0'));
                expect(result.newVersion, equals(vesion));
                expect(result.canUpdate, isTrue);
              });
              test('Error response as <String> from Google Play Store',
                  () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;
                const errorMessage = "It's error";

                when(mockHttpClient.get(any)).thenThrow(errorMessage);

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.currentVersion, equals('1.0.0'));
                expect(result.errorMessage, errorMessage);
                expect(result.newVersion, isNull);
                expect(result.canUpdate, isFalse);
              });
              test('Error response from Google Play Store', () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;

                when(mockHttpClient.get(any))
                    .thenAnswer((_) async => http.Response('Error', 404));

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.errorMessage, isNotNull);
                expect(result.canUpdate, isFalse);
              });
            });
            group('Apk Pure -', () {
              test('Successful check for Google Play Store', () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;
                const vesion = '1.2.3';

                when(mockHttpClient.get(any)).thenAnswer(
                  (_) async => http.Response(
                    '<div class="details-sdk"><span itemprop="version">$vesion</span>for Android</div>',
                    200,
                  ),
                );

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                  androidStore: AndroidStore.apkPure,
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.currentVersion, equals('1.0.0'));
                expect(result.newVersion, equals(vesion));
                expect(result.canUpdate, isTrue);
              });
              test('Error response as <String> from Google Play Store',
                  () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;
                const errorMessage = "It's error";

                when(mockHttpClient.get(any)).thenThrow(errorMessage);

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                  androidStore: AndroidStore.apkPure,
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.currentVersion, equals('1.0.0'));
                expect(result.errorMessage, errorMessage);
                expect(result.newVersion, isNull);
                expect(result.canUpdate, isFalse);
              });
              test('Error response from Google Play Store', () async {
                debugDefaultTargetPlatformOverride = TargetPlatform.android;

                when(mockHttpClient.get(any))
                    .thenAnswer((_) async => http.Response('Error', 404));

                final checker = InStoreAppVersionChecker(
                  currentVersion: '1.0.0',
                  appId: 'com.example.app',
                  androidStore: AndroidStore.apkPure,
                )..setHttpClient(mockHttpClient);

                final result = await checker.checkUpdate();

                expect(result.errorMessage, isNotNull);
                expect(result.canUpdate, isFalse);
                expect(result.toString(), isA<String>());
              });
            });
          });
        }));
