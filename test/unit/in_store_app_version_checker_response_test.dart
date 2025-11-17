/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 13 November 2025
 */

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group(r'InStoreAppVersionChecker$Response - ', () {
      group('success', () {
        test('creates success response with expected flags', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3',
            newVersion: '1.2.3',
            appURL: 'https://example.com/app',
          );
          expect(r.type, InStoreAppVersionChecker$Response$Type.success);
          expect(r.isSuccess, isTrue);
          expect(r.isError, isFalse);
          expect(r.currentVersion, '1.2.3');
          expect(r.newVersion, '1.2.3');
          expect(r.appURL, 'https://example.com/app');
          // same versions -> no update
          expect(r.canUpdate, isFalse);
        });

        test('canUpdate true when newVersion greater (patch)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3',
            newVersion: '1.2.4',
          );
          expect(r.canUpdate, isTrue);
        });
      });

      group('error', () {
        test('creates error response with expected flags', () {
          final r = InStoreAppVersionChecker$Response.error(
            currentVersion: '2.0.0',
            newVersion: '2.1.0',
            errorMessage: 'Network error',
            error: Exception('timeout'),
            stackTrace: StackTrace.current,
          );
          expect(r.type, InStoreAppVersionChecker$Response$Type.error);
          expect(r.isError, isTrue);
          expect(r.isSuccess, isFalse);
          expect(r.errorMessage, 'Network error');
          expect(r.error, isA<Exception>());
          expect(r.stackTrace, isNotNull);
          // newVersion higher -> still can update
          expect(r.canUpdate, isTrue);
        });
      });

      group('canUpdate logic', () {
        final cases = <Map<String, Object?>>[
          {
            'current': '1.2.3',
            'new': '1.2.3',
            'expected': false,
            'desc': 'equal versions'
          },
          {
            'current': '1.2.3',
            'new': '1.2.4',
            'expected': true,
            'desc': 'patch increase'
          },
          {
            'current': '1.2.3',
            'new': '1.3.0',
            'expected': true,
            'desc': 'minor increase'
          },
          {
            'current': '1.2.3',
            'new': '2.0.0',
            'expected': true,
            'desc': 'major increase'
          },
          {
            'current': '1.2.3',
            'new': '1.2.2',
            'expected': false,
            'desc': 'patch downgrade'
          },
          {
            'current': '1.2.3',
            'new': '1.1.9',
            'expected': false,
            'desc': 'minor downgrade'
          },
          {
            'current': '1.2.3',
            'new': '0.9.9',
            'expected': false,
            'desc': 'major downgrade'
          },
          {
            'current': '1.2',
            'new': '1.2.1',
            'expected': true,
            'desc': 'longer new version indicates update'
          },
          {
            'current': '1.2.1',
            'new': '1.2',
            'expected': false,
            'desc': 'shorter new version (downgrade)'
          },
          {
            'current': '1.2.3.4',
            'new': '1.2.3',
            'expected': false,
            'desc': 'current longer & higher -> no update'
          },
          {
            'current': '1.2.alpha',
            'new': '1.2.1',
            'expected': true,
            'desc': 'non-numeric treated as 0, new higher patch'
          },
          {
            'current': '1.2.1',
            'new': '1.2.alpha',
            'expected': false,
            'desc': 'non-numeric in new -> parsed 0, downgrade'
          },
          {
            'current': '1.2.3',
            'new': null,
            'expected': false,
            'desc': 'null newVersion falls back to currentVersion'
          },
        ];

        for (final c in cases) {
          test('canUpdate: ${c['desc']}', () {
            final r = InStoreAppVersionChecker$Response.success(
              currentVersion: c['current']! as String,
              newVersion: c['new'] as String?,
            );
            expect(r.canUpdate, c['expected']);
          });
        }
      });

      group('equality & hashCode', () {
        test('equal objects have same hashCode', () {
          const a = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            appURL: 'url',
          );
          const b = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            appURL: 'url',
          );
          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        });

        test('different newVersion not equal', () {
          const a = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
          );
          const b = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.2.0',
          );
          expect(a == b, isFalse);
        });

        test('different appURL not equal', () {
          const a = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            appURL: 'urlA',
          );
          const b = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            appURL: 'urlB',
          );
          expect(a == b, isFalse);
        });
      });

      group('toString', () {
        test('success contains expected substrings', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '3.4.5',
            newVersion: '3.5.0',
            appURL: 'https://example.com',
          );
          final s = r.toString();
          expect(s, contains('Current version: 3.4.5'));
          expect(s, contains('New version: 3.5.0'));
          expect(s, contains('App url: https://example.com'));
          expect(s, contains('Can update: true'));
        });

        test('error contains error fields', () {
          final r = InStoreAppVersionChecker$Response.error(
            currentVersion: '3.4.5',
            newVersion: '3.5.0',
            appURL: 'https://example.com',
            errorMessage: 'Failure',
            error: ArgumentError('bad'),
            stackTrace: StackTrace.current,
          );
          final s = r.toString();
          expect(s, contains('Current version: 3.4.5'));
          expect(s, contains('New version: 3.5.0'));
          expect(s, contains('App url: https://example.com'));
          expect(s, contains('Can update: true'));
          expect(s, contains('Error message: Failure'));
          expect(s, contains('Error:'));
          expect(s, contains('Stack trace:'));
        });
      });

      group('pre-release ordering (lexicographic)', () {
        test('pre-release vs release (preA != null, preB == null) => false',
            () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-beta',
            newVersion: '1.0.0',
          );
          expect(r.canUpdate, isFalse);
        });
        test('release vs pre-release (preA null, preB != null) => true', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.0.0-beta',
          );
          expect(r.canUpdate, isTrue);
        });
        test('alpha -> beta (alpha < beta)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-alpha',
            newVersion: '1.0.0-beta',
          );
          expect(r.canUpdate, isTrue);
        });
        test('beta -> alpha (beta > alpha)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-beta',
            newVersion: '1.0.0-alpha',
          );
          expect(r.canUpdate, isFalse);
        });
        test('alpha-beta -> alpha-gamma', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-alpha-beta',
            newVersion: '1.0.0-alpha-gamma',
          );
          expect(r.canUpdate, isTrue);
        });
        test('alpha-2 -> alpha-10 (alpha-2 > alpha-10)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-alpha-2',
            newVersion: '1.0.0-alpha-10',
          );
          expect(r.canUpdate, isTrue);
        });
        test('alpha-22 -> alpha-10 (alpha-10 < alpha-22)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-alpha-10',
            newVersion: '1.0.0-alpha-22',
          );
          expect(r.canUpdate, isTrue);
        });
        test('trailing dash vs release', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0-',
            newVersion: '1.0.0',
          );
          expect(r.canUpdate, isFalse);
        });
        test('release vs trailing dash', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.0.0-',
          );
          expect(r.canUpdate, isTrue);
        });
      });

      group('build metadata ignored', () {
        test('same core different build => no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3+10',
            newVersion: '1.2.3+99',
          );
          expect(r.canUpdate, isFalse);
        });
        test('higher core different build => update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3+10',
            newVersion: '1.2.4+1',
          );
          expect(r.canUpdate, isTrue);
        });
        test('pre-release vs same core release+build', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3-beta+5',
            newVersion: '1.2.3+7',
          );
          // pre-release < release => false
          expect(r.canUpdate, isFalse);
        });
      });

      group('normalization & stripping', () {
        test('spaces & emoji stripped for comparison', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: ' v1.0.0🔥 ',
            newVersion: ' v1.0.1🚀 ',
          );
          expect(r.canUpdate, isTrue);
        });
        test('non-numeric entirely removed newVersion -> no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '🔥🔥🔥',
          );
          expect(r.canUpdate, isFalse);
        });
        test('current all non-numeric, new numeric => update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: 'abc',
            newVersion: '1.0.0',
          );
          expect(r.canUpdate, isTrue);
        });
        test('leading zeros equivalence', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '01.002.003',
            newVersion: '1.2.3',
          );
          expect(r.canUpdate, isFalse);
        });
        test('leading zeros vs higher patch', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '01.002.003',
            newVersion: '1.2.4',
          );
          expect(r.canUpdate, isTrue);
        });
      });

      group('long & deep segment comparison', () {
        test('deep chain last segment increment', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.1.1.1.1.1.1',
            newVersion: '1.1.1.1.1.1.2',
          );
          expect(r.canUpdate, isTrue);
        });
        test('deep chain last segment downgrade', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.1.1.1.1.1.2',
            newVersion: '1.1.1.1.1.1.1',
          );
          expect(r.canUpdate, isFalse);
        });
        test('extra segment newVersion higher', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3',
            newVersion: '1.2.3.1',
          );
          expect(r.canUpdate, isTrue);
        });
        test('current has extra higher segment', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3.4',
            newVersion: '1.2.3',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('numeric vs alpha segments', () {
        test('alpha treated as 0 => update when numeric new higher', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.a.0',
            newVersion: '1.1.0',
          );
          expect(r.canUpdate, isTrue);
        });
        test('numeric current vs alpha new => downgrade', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.1.0',
            newVersion: '1.a.0',
          );
          expect(r.canUpdate, isFalse);
        });
        test('all alpha current -> numeric new => update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: 'x.y.z',
            newVersion: '1.0.0',
          );
          expect(r.canUpdate, isTrue);
        });
        test('numeric current -> all alpha new => no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: 'x.y.z',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('literal "null" handling', () {
        test('"null" string equals no change', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: 'null',
          );
          expect(r.newVersion, 'null');
          expect(r.canUpdate, isFalse);
        });
        test('"null" vs higher numeric', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.0.1',
          );
          expect(r.canUpdate, isTrue);
        });
        test('"null" vs lower numeric', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '2.0.0',
            newVersion: 'null',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('whitespace variations', () {
        test('trim both versions', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: ' 1.2.3 ',
            newVersion: ' 1.2.4 ',
          );
          expect(r.canUpdate, isTrue);
        });
        test('whitespace newVersion only', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.3',
            newVersion: '   ',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('extreme numeric jumps', () {
        test('huge major jump', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1000.0.0',
          );
          expect(r.canUpdate, isTrue);
        });
        test('huge major downgrade', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1000.0.0',
            newVersion: '1.0.0',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('single segment versions', () {
        test('1 -> 2 update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1',
            newVersion: '2',
          );
          expect(r.canUpdate, isTrue);
        });
        test('2 -> 1 no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '2',
            newVersion: '1',
          );
          expect(r.canUpdate, isFalse);
        });
        test('1-alpha -> 1 release (pre vs none)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1-alpha',
            newVersion: '1',
          );
          expect(r.canUpdate, isFalse);
        });
        test('1 -> 1-alpha (release vs pre)', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1',
            newVersion: '1-alpha',
          );
          expect(r.canUpdate, isTrue);
        });
      });

      group('error response canUpdate passthrough', () {
        test('error with higher newVersion still update', () {
          const r = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.0.1',
            errorMessage: 'fail',
          );
          expect(r.isError, isTrue);
          expect(r.canUpdate, isTrue);
        });
        test('error same version no update', () {
          const r = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.0.0',
            errorMessage: 'fail',
          );
          expect(r.canUpdate, isFalse);
        });
        test('error lower version no update', () {
          const r = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.1',
            newVersion: '1.0.0',
            errorMessage: 'fail',
          );
          expect(r.canUpdate, isFalse);
        });
      });

      group('equality ignores error fields', () {
        test('two error responses differ only by message => equal', () {
          const a = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            errorMessage: 'A',
          );
          const b = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            errorMessage: 'B',
          );
          expect(a, equals(b));
        });
        test('two error responses differ only by error object => equal', () {
          final a = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            errorMessage: 'msg',
            error: Exception('e1'),
          );
          final b = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
            errorMessage: 'msg',
            error: Exception('e2'),
          );
          expect(a, equals(b));
        });
      });

      group('hashCode differences', () {
        test('different newVersion => hashCode differs', () {
          const a = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
          );
          const b = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.2.0',
          );
          expect(a.hashCode == b.hashCode, isFalse);
        });
        test('different currentVersion => hashCode differs', () {
          const a = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
            newVersion: '1.1.0',
          );
          const b = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.1',
            newVersion: '1.1.0',
          );
          expect(a.hashCode == b.hashCode, isFalse);
        });
      });

      group('toString edge cases', () {
        test('success without appURL newVersion', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.0.0',
          );
          final s = r.toString();
          expect(s, contains('Current version: 1.0.0'));
          expect(s, contains('New version: null'));
          expect(s, contains('App url: null'));
          expect(s, contains('Can update: false'));
          expect(s, isNot(contains('Error message:')));
        });
        test('error without newVersion still prints fields', () {
          const r = InStoreAppVersionChecker$Response.error(
            currentVersion: '1.0.0',
            errorMessage: 'boom',
          );
          final s = r.toString();
          expect(s, contains('Current version: 1.0.0'));
          expect(s, contains('New version: null'));
          expect(s, contains('Error message: boom'));
        });
      });

      group('regression: trailing zeros & length', () {
        test('1.2 vs 1.2.0 => no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2',
            newVersion: '1.2.0',
          );
          expect(r.canUpdate, isFalse);
        });
        test('1.2.0 vs 1.2.1 => update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.0',
            newVersion: '1.2.1',
          );
          expect(r.canUpdate, isTrue);
        });
        test('1.2.0 vs 1.2 => no update', () {
          const r = InStoreAppVersionChecker$Response.success(
            currentVersion: '1.2.0',
            newVersion: '1.2',
          );
          expect(r.canUpdate, isFalse);
        });
      });
    });
