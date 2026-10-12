/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diagnostics use the store message independently of the error', () {
    const underlyingError = FormatException('invalid listing');
    const error = AppStoreException(
      message: 'Lookup failed.',
      error: underlyingError,
    );
    const errorWithoutUnderlyingError = AppStoreException(
      message: 'Listing not found.',
    );

    expect(error.error, same(underlyingError));
    expect(error.toString(), 'Lookup failed.');
    expect(errorWithoutUnderlyingError.error, isNull);
    expect(errorWithoutUnderlyingError.toString(), 'Listing not found.');
  });
}
