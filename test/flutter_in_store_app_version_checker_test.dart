/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 11 December 2023
 */

import 'package:flutter_test/flutter_test.dart';

import 'unit/in_store_app_version_checker_android_stores_test.dart'
    as android_stores_test;
import 'unit/in_store_app_version_checker_locale_test.dart' as locale_test;
import 'unit/in_store_app_version_checker_response_test.dart' as response_test;
import 'unit/in_store_app_version_checker_test.dart' as checker_test;

void main() {
  group('Unit_test -', () {
    group('Android stores -', android_stores_test.main);
    locale_test.main();
    response_test.main();
    checker_test.main();
  });
}
