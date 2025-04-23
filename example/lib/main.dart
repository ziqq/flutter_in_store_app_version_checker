import 'dart:async';
import 'dart:developer' as d;
import 'dart:io' as io;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

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

const _verticalSpacing = SizedBox(height: 16);

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
        title: 'In Store App Version Checker Example Gradle 8',
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

  InStoreAppVersionCheckerResult? _tiktok;
  InStoreAppVersionCheckerResult? _roblox;
  InStoreAppVersionCheckerResult? _freefireth;
  InStoreAppVersionCheckerResult? _wildberries;
  InStoreAppVersionCheckerResult? _ozon;

  @override
  void initState() {
    super.initState();
    _tiktokChecker = InStoreAppVersionChecker(
      appId: io.Platform.isAndroid
          ? kTikTokStoreIDPair.googlePlayID
          : kTikTokStoreIDPair.appleStoreID,
    );
    _robloxChecker = InStoreAppVersionChecker(
      appId: io.Platform.isAndroid
          ? kRobloxStoreIDPair.googlePlayID
          : kRobloxStoreIDPair.appleStoreID,
    );
    _freefirethChecker = InStoreAppVersionChecker(
      appId: io.Platform.isAndroid
          ? kFreefirethStoreIDPair.googlePlayID
          : kFreefirethStoreIDPair.appleStoreID,
    );
    _wildberriesChecker = InStoreAppVersionChecker(
      appId: io.Platform.isAndroid
          ? kWildberriesStoreIDPair.googlePlayID
          : kWildberriesStoreIDPair.appleStoreID,
    );
    _ozonChecker = InStoreAppVersionChecker(
      appId: io.Platform.isAndroid
          ? kOzonStoreIDPair.googlePlayID
          : kOzonStoreIDPair.appleStoreID,
    );
  }

  Future<void> _checkVersion() async {
    await Future.wait([
      _tiktokChecker.checkUpdate().then((result) => _tiktok = result),
      _robloxChecker.checkUpdate().then((result) => _roblox = result),
      _freefirethChecker.checkUpdate().then((result) => _freefireth = result),
      _wildberriesChecker.checkUpdate().then((result) => _wildberries = result),
      _ozonChecker.checkUpdate().then((result) => _ozon = result),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: false,
          centerTitle: true,
          title: const Text(
            'Example with gradle 8',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              iconSize: 20,
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
                    children: [
                      if (_tiktok != null) ...[
                        _AppSection(title: 'Tik Tok', item: _tiktok!),
                        _verticalSpacing,
                      ],
                      if (_roblox != null) ...[
                        _AppSection(title: 'Roblox', item: _roblox!),
                        _verticalSpacing,
                      ],
                      if (_freefireth != null) ...[
                        _AppSection(title: 'Freefeireth', item: _freefireth!),
                        _verticalSpacing,
                      ],
                      if (_wildberries != null) ...[
                        _AppSection(title: 'Willberies', item: _wildberries!),
                        _verticalSpacing,
                      ],
                      if (_ozon != null) ...[
                        _AppSection(title: 'Ozon', item: _ozon!),
                        _verticalSpacing,
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

/// {@template main}
/// _AppSection widget.
/// {@endtemplate}
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
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 5),
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
