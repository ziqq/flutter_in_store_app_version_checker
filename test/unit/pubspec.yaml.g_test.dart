// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff
import 'package:flutter_in_store_app_version_checker/src/model/pubspec.yaml.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group(
    'Unit_tests -',
    () => group('pubspec.yaml.g -', () {
          group('timestamp -', () {
            test('When called, should be return <DateTime>', () {
              expect(Pubspec.timestamp, isA<DateTime>());
            });
          });
        }));
