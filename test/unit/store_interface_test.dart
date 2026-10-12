/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 08 October 2026
 */

import 'package:flutter_in_store_app_version_checker/src/store/apk_pure_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_native_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/app_gallery_web_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/apple_app_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/google_play_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/ru_store.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  test('store names distinguish all supported implementations', () {
    final client = MockClient(
      (_) async => throw StateError('Unexpected lookup'),
    );
    addTearDown(client.close);
    final stores = <IStore>[
      Store$AppStore(client),
      Store$GooglePlay(client),
      Store$ApkPure(client),
      Store$RuStore(client),
      Store$AppGalleryWeb(client),
      const Store$AppGalleryNative(),
    ];

    expect(stores.map((store) => store.name), <String>[
      'Apple App Store',
      'Google Play',
      'ApkPure',
      'RuStore',
      'AppGallery',
      'AppGallery native',
    ]);
  });
}
