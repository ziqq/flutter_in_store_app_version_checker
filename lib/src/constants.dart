/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 07 October 2026
 */

import 'package:meta/meta.dart';

/// Matches `language`, `language-REGION` and `language-Script-REGION`
/// locales with either `-` or `_` separators.
///
/// Groups: 1 — language, 2 — script, 3 — region.
@internal
final RegExp kStoreLocalePattern = RegExp(
  '^([a-z]{2,3}|[a-z]{5,8})'
  '(?:[-_]([a-z]{4}))?'
  r'(?:[-_]([a-z]{2}|[0-9]{3}))?$',
  caseSensitive: false,
);
