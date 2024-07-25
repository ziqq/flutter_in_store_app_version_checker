// Autor - <a.a.ustinoff@gmail.com> Anton Ustinoff, 11 December 2023

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks([], customMocks: [MockSpec<http.Client>()])
void getGenerateMocks() {}

const fakeAndroidBuildVersion = <String, dynamic>{
  'sdkInt': 16,
  'baseOS': 'baseOS',
  'previewSdkInt': 30,
  'release': 'release',
  'codename': 'codename',
  'incremental': 'incremental',
  'securityPatch': 'securityPatch',
};

const fakeDisplayMetrics = <String, dynamic>{
  'widthPx': 1080.0,
  'heightPx': 2220.0,
  'xDpi': 530.0859,
  'yDpi': 529.4639,
};

const fakeSupportedAbis = <String>['arm64-v8a', 'x86', 'x86_64'];
const fakeSupported32BitAbis = <String?>['x86 (IA-32)', 'MMX'];
const fakeSupported64BitAbis = <String?>['x86-64', 'MMX', 'SSSE3'];
const fakeSystemFeatures = ['FEATURE_AUDIO_PRO', 'FEATURE_AUDIO_OUTPUT'];

const fakeAndroidDeviceInfo = <String, dynamic>{
  'id': 'id',
  'host': 'host',
  'tags': 'tags',
  'type': 'type',
  'model': 'model',
  'name': 'name',
  'board': 'board',
  'brand': 'Google',
  'device': 'device',
  'product': 'product',
  'display': 'display',
  'hardware': 'hardware',
  'isPhysicalDevice': true,
  'bootloader': 'bootloader',
  'fingerprint': 'fingerprint',
  'manufacturer': 'manufacturer',
  'supportedAbis': fakeSupportedAbis,
  'systemFeatures': fakeSystemFeatures,
  'version': fakeAndroidBuildVersion,
  'supported64BitAbis': fakeSupported64BitAbis,
  'supported32BitAbis': fakeSupported32BitAbis,
  'displayMetrics': fakeDisplayMetrics,
  'serialNumber': '23',
};

const iosUtsnameMap = <String, dynamic>{
  'release': 'release',
  'version': 'version',
  'machine': 'machine',
  'sysname': 'sysname',
  'nodename': 'nodename',
};

const iosDeviceInfoMap = <String, dynamic>{
  'name': 'name',
  'model': 'model',
  'utsname': iosUtsnameMap,
  'systemName': 'systemName',
  'isPhysicalDevice': 'true',
  'systemVersion': 'systemVersion',
  'localizedModel': 'localizedModel',
  'identifierForVendor': 'identifierForVendor',
};
