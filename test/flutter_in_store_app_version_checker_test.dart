/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 11 December 2023
 */

import 'package:flutter_test/flutter_test.dart';

import 'unit/in_store_app_version_checker_legacy_test.dart'
    as legacy_checker_test;
import 'unit/in_store_app_version_checker_response_test.dart' as response_test;
import 'unit/in_store_app_version_checker_test.dart' as checker_test;

void main() {
  group('Unit_test -', () {
    legacy_checker_test.main();
    response_test.main();
    checker_test.main();
  });
}
