import 'dart:async';
import 'dart:developer' as d;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

/// A pair of store IDs for Google Play Store and Apple App Store,
/// containing a current version of the app.
typedef StoreIDPair = ({
  String googlePlayID,
  String appleStoreID,
  String currentVersion,
});

//? Has in Pure Store and Google Play Store
const StoreIDPair kTikTokStoreIDPair = (
  googlePlayID: 'com.zhiliaoapp.musically',
  appleStoreID: 'com.zhiliaoapp.musically',
  currentVersion: '40.4.3',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kRobloxStoreIDPair = (
  googlePlayID: 'com.roblox.client',
  appleStoreID: 'com.roblox.client',
  currentVersion: '2.698.941',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kFreefirethStoreIDPair = (
  googlePlayID: 'com.dts.freefireth',
  appleStoreID: 'com.dts.freefireth',
  currentVersion: '1.118.1',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kWildberriesStoreIDPair = (
  googlePlayID: 'com.wildberries.ru',
  appleStoreID: 'com.wildberries.ru',
  currentVersion: '7.3.9000',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kOzonStoreIDPair = (
  googlePlayID: 'ru.ozon.app.android',
  appleStoreID: 'ru.ozon.app',
  currentVersion: '18.41.0',
);

//? Has in Pure Store and Google Play Store
const StoreIDPair kAmotoStoreIDPair = (
  googlePlayID: 'de.conio.amoMoto',
  appleStoreID: 'de.conio.amoMoto',
  currentVersion: '1.1.3',
);

void main() => runZonedGuarded<void>(
  () => runApp(const App()),
  (e, s) => d.log('Top level exception: $e\n$s'),
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
  late final InStoreAppVersionChecker _freefirethChecker;
  late final InStoreAppVersionChecker _robloxChecker;
  late final InStoreAppVersionChecker _tiktokChecker;

  InStoreAppVersionCheckerResult? _freefireth;
  InStoreAppVersionCheckerResult? _roblox;
  InStoreAppVersionCheckerResult? _tiktok;

  InStoreAppVersionChecker$Response? _wildberries;
  InStoreAppVersionChecker$Response? _amoMoto;
  InStoreAppVersionChecker$Response? _ozon;

  /// Whether the app is running on Android.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Whether the app is running on iOS.
  // ignore: unused_element
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _freefirethChecker = InStoreAppVersionChecker(
      appId: _isAndroid
          ? kFreefirethStoreIDPair.googlePlayID
          : kFreefirethStoreIDPair.appleStoreID,
      currentVersion: kFreefirethStoreIDPair.currentVersion,
    );
    _robloxChecker = InStoreAppVersionChecker(
      appId: _isAndroid
          ? kRobloxStoreIDPair.googlePlayID
          : kRobloxStoreIDPair.appleStoreID,
      currentVersion: kRobloxStoreIDPair.currentVersion,
    );
    _tiktokChecker = InStoreAppVersionChecker(
      appId: _isAndroid
          ? kTikTokStoreIDPair.googlePlayID
          : kTikTokStoreIDPair.appleStoreID,
      currentVersion: kTikTokStoreIDPair.currentVersion,
    );
  }

  Future<void> _checkVersion() async {
    try {
      final amotoParams = InStoreAppVersionChecker$Params(
        currentVersion: kAmotoStoreIDPair.currentVersion,
        packageName: _isAndroid
            ? kAmotoStoreIDPair.googlePlayID
            : kAmotoStoreIDPair.appleStoreID,
        locale: 'en',
      );
      final ozonParams = InStoreAppVersionChecker$Params(
        currentVersion: kOzonStoreIDPair.currentVersion,
        packageName: _isAndroid
            ? kOzonStoreIDPair.googlePlayID
            : kOzonStoreIDPair.appleStoreID,
        locale: 'ru',
      );
      final wildberisParams = InStoreAppVersionChecker$Params(
        currentVersion: kWildberriesStoreIDPair.currentVersion,
        packageName: _isAndroid
            ? kWildberriesStoreIDPair.googlePlayID
            : kWildberriesStoreIDPair.appleStoreID,
        locale: 'ru',
      );
      _ozon = await InStoreAppVersionChecker.instance.checkUpdate(ozonParams);
      _amoMoto = await InStoreAppVersionChecker.instance.checkUpdate(
        amotoParams,
      );
      _wildberries = await InStoreAppVersionChecker.instance.checkUpdate(
        wildberisParams,
      );

      await [
        _freefirethChecker.checkUpdate().then((result) => _freefireth = result),
        _robloxChecker.checkUpdate().then((result) => _roblox = result),
        _tiktokChecker.checkUpdate().then((result) => _tiktok = result),
      ].wait;
    } on Object catch (e, _) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Error checking for updates: $e',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            backgroundColor: CupertinoDynamicColor.resolve(
              CupertinoColors.systemRed,
              context,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: const Text(
        'In Store App Version Checker Example',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          iconSize: 24,
          padding: EdgeInsets.zero,
          onPressed: _checkVersion,
          icon: const Icon(CupertinoIcons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: _checkVersion(),
          builder: (context, snapshot) {
            // --- Loading state --- //
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            // --- Error state --- //
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemRed,
                      context,
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                spacing: 16,
                children: [
                  _Section(title: 'Freefeireth', item: _freefireth),
                  _Section(title: 'Roblox', item: _roblox),
                  _Section(title: 'Tik Tok', item: _tiktok),
                  _Section(title: 'Ozon', item: _ozon),
                  _Section(title: 'Willberies', item: _wildberries),
                  _Section(title: 'Amo moto', item: _amoMoto),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// _Section widget.
/// {@macro example}
class _Section extends StatelessWidget {
  /// {@macro main}
  const _Section({
    required this.title,
    required this.item,
    super.key, // ignore: unused_element_parameter
  }) : assert(
         item is InStoreAppVersionCheckerResult ||
             item is InStoreAppVersionChecker$Response,
         r'item must be of type InStoreAppVersionCheckerResult or InStoreAppVersionChecker$Response',
       );

  final String title;
  final Object? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();
    final canUpdate = switch (item) {
      InStoreAppVersionChecker$Response i => i.canUpdate,
      InStoreAppVersionCheckerResult i => i.canUpdate,
      _ => false,
    };
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Row(
            spacing: 10,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
              if (canUpdate) ...[
                Badge(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  backgroundColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGreen,
                    context,
                  ).withAlpha(25),
                  label: const Text('Can update'),
                  textColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGreen,
                    context,
                  ),
                ),
              ],
            ],
          ),
          Text(
            item.toString(),
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
