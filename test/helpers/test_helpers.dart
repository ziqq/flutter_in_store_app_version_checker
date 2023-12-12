// Autor - <a.a.ustinoff@gmail.com> Anton Ustinoff, 11 December 2023
// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

export 'test_helpers.mocks.dart';
export 'mocks/device_info_mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<http.Client>(),
  MockSpec<PackageInfo>(),
])
void getGenerateMocks() {}
