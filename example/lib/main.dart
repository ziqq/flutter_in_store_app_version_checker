import 'dart:async';
import 'dart:developer' as d;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

/// A pair of store IDs for Google Play Store and Apple App Store.
typedef StoreIDPair = ({String googlePlayID, String appleStoreID});

//? Has in Pure Store and Google Play Store
const StoreIDPair kTikTokStoreIDPair = (
  googlePlayID: 'com.zhiliaoapp.musically',
  appleStoreID: 'com.zhiliaoapp.musically',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kRobloxStoreIDPair = (
  googlePlayID: 'com.roblox.client',
  appleStoreID: 'com.roblox.client',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kFreefirethStoreIDPair = (
  googlePlayID: 'com.dts.freefireth',
  appleStoreID: 'com.dts.freefireth',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kWildberriesStoreIDPair = (
  googlePlayID: 'com.wildberries.ru',
  appleStoreID: 'com.wildberries.ru',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kOzonStoreIDPair = (
  googlePlayID: 'ru.ozon.app.android',
  appleStoreID: 'ru.ozon.app',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair test = (
  googlePlayID: 'de.conio.amoMoto',
  appleStoreID: 'de.conio.amoMoto',
);

void main() => runZonedGuarded<void>(
      () => runApp(const App()),
      (error, stackTrace) => d.log('Top level exception: $error\n$stackTrace'),
    );

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'In Store App Version Checker Example',
        theme: ThemeData.dark(),
        home: const Example(),
      );
}

/// {@template example}
/// Example widget of using the `InStoreAppVersionChecker` plugin.
/// {@endtemplate}
class Example extends StatefulWidget {
  /// {@macro example}
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

/// State of the [Example] widget.
class _ExampleState extends State<Example> {
  late final InStoreAppVersionChecker _tiktokChecker;
  late final InStoreAppVersionChecker _robloxChecker;
  late final InStoreAppVersionChecker _freefirethChecker;
  late final InStoreAppVersionChecker _wildberriesChecker;
  late final InStoreAppVersionChecker _ozonChecker;
  late final InStoreAppVersionChecker _testChecker;

  InStoreAppVersionCheckerResult? _tiktok;
  InStoreAppVersionCheckerResult? _roblox;
  InStoreAppVersionCheckerResult? _freefireth;
  InStoreAppVersionCheckerResult? _wildberries;
  InStoreAppVersionCheckerResult? _ozon;
  InStoreAppVersionCheckerResult? _testResult;

  /// Whether the app is running on Android.
  bool get _asAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Whether the app is running on iOS.
  // ignore: unused_element
  bool get _asIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _tiktokChecker = InStoreAppVersionChecker(
      appId: _asAndroid
          ? kTikTokStoreIDPair.googlePlayID
          : kTikTokStoreIDPair.appleStoreID,
    );
    _robloxChecker = InStoreAppVersionChecker(
      appId: _asAndroid
          ? kRobloxStoreIDPair.googlePlayID
          : kRobloxStoreIDPair.appleStoreID,
    );
    _freefirethChecker = InStoreAppVersionChecker(
      appId: _asAndroid
          ? kFreefirethStoreIDPair.googlePlayID
          : kFreefirethStoreIDPair.appleStoreID,
    );
    _wildberriesChecker = InStoreAppVersionChecker(
      appId: _asAndroid
          ? kWildberriesStoreIDPair.googlePlayID
          : kWildberriesStoreIDPair.appleStoreID,
      locale: 'ru',
    );
    _ozonChecker = InStoreAppVersionChecker(
      appId: _asAndroid
          ? kOzonStoreIDPair.googlePlayID
          : kOzonStoreIDPair.appleStoreID,
      locale: 'ru',
    );
    _testChecker = InStoreAppVersionChecker(
      appId: _asAndroid ? test.googlePlayID : test.appleStoreID,
      locale: 'en',
    );
  }

  Future<void> _checkVersion() async {
    await [
      _tiktokChecker.checkUpdate().then((result) => _tiktok = result),
      _robloxChecker.checkUpdate().then((result) => _roblox = result),
      _freefirethChecker.checkUpdate().then((result) => _freefireth = result),
      _wildberriesChecker.checkUpdate().then((result) => _wildberries = result),
      _ozonChecker.checkUpdate().then((result) => _ozon = result),
      _testChecker.checkUpdate().then((result) => _testResult = result),
    ].wait;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: false,
          centerTitle: true,
          title: const Text(
            'In Store App Version Checker Example',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              iconSize: 24,
              padding: EdgeInsets.zero,
              onPressed: _checkVersion,
              icon: const Icon(CupertinoIcons.refresh),
            )
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder(
              future: _checkVersion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    spacing: 16,
                    children: [
                      if (_tiktok != null) ...[
                        _AppSection(title: 'Tik Tok', item: _tiktok!),
                      ],
                      if (_roblox != null) ...[
                        _AppSection(title: 'Roblox', item: _roblox!),
                      ],
                      if (_freefireth != null) ...[
                        _AppSection(title: 'Freefeireth', item: _freefireth!),
                      ],
                      if (_wildberries != null) ...[
                        _AppSection(title: 'Willberies', item: _wildberries!),
                      ],
                      if (_ozon != null) ...[
                        _AppSection(title: 'Ozon', item: _ozon!),
                      ],
                      if (_testResult != null) ...[
                        _AppSection(title: 'Test', item: _testResult!),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

/// _AppSection widget.
/// {@macro example}
class _AppSection extends StatelessWidget {
  /// {@macro main}
  const _AppSection({
    required this.title,
    required this.item,
    super.key, // ignore: unused_element_parameter
  });

  final String title;
  final InStoreAppVersionCheckerResult item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            Text(
              item.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
}
