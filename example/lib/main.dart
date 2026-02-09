import 'dart:async';
import 'dart:developer' as dev show log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

/// A pair of store IDs for `Google Play` and `App Store`,
/// containing a current version of the app.
typedef StoreIDPair = ({
  String googlePlayID,
  String appleStoreID,
  String currentVersion,
});

// TikTok
// bundle id: com.zhiliaoapp.musically, https://www.ntc.swiss/hubfs/NTC-security-analysis-tiktok-v1.0-en.pdf?utm_source=chatgpt.com
const StoreIDPair kTikTokStoreIDPair = (
  googlePlayID: 'com.zhiliaoapp.musically',
  appleStoreID: 'com.zhiliaoapp.musically',
  currentVersion: '43.7.0',
);

// Roblox
// bundle id: com.roblox.robloxmobile, https://apptopia.com/ios/app/431946152/about?utm_source=chatgpt.com
const StoreIDPair kRobloxStoreIDPair = (
  googlePlayID: 'com.roblox.client',
  appleStoreID: 'com.roblox.robloxmobile',
  currentVersion: '2.706.752',
);

// Free Fire (TH)
// bundle id: com.dts.freefireth, https://apptopia.com/ios/app/1300146617/about?utm_source=chatgpt.com
const StoreIDPair kFreefirethStoreIDPair = (
  googlePlayID: 'com.dts.freefireth',
  appleStoreID: 'com.dts.freefireth',
  currentVersion: '1.120.1',
);

// Wildberries
// bundle id из AASA wildberries.ru, https://well-known.dev/resources/apple_app_site_association/sites/wildberries.ru?utm_source=chatgpt.com
const StoreIDPair kWildberriesStoreIDPair = (
  googlePlayID: 'com.wildberries.ru',
  appleStoreID: 'RU.WILDBERRIES.MOBILEAPP',
  currentVersion: '',
);

// OZON
// bundle id (аналитика/ASO источники): ru.ozon.OzonStore, https://platform.foxdata.com/en/app-profile/407804998/BY/as?utm_source=chatgpt.com
const StoreIDPair kOzonStoreIDPair = (
  googlePlayID: 'ru.ozon.app.android',
  appleStoreID: 'ru.ozon.OzonStore',
  currentVersion: '',
);

void main() => runZonedGuarded<void>(
  () => runApp(const App()),
  (e, s) => dev.log('Top level exception: $e\n$s'),
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
  final ValueNotifier<bool> _updating = ValueNotifier<bool>(false);
  late final InStoreAppVersionChecker _freefirethChecker;
  late final InStoreAppVersionChecker _robloxChecker;
  late final InStoreAppVersionChecker _tiktokChecker;
  final _checker = InStoreAppVersionChecker.instance;

  InStoreAppVersionCheckerResult? _freefireth;
  InStoreAppVersionCheckerResult? _roblox;
  InStoreAppVersionCheckerResult? _tiktok;

  InStoreAppVersionChecker$Response? _wildberries;
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

  @override
  void dispose() {
    _updating.dispose();
    super.dispose();
  }

  Future<void> _checkVersion({bool? refresh}) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (refresh != null) _updating.value = true;
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

      _wildberries = await _checker.checkUpdate(wildberisParams);
      _ozon = await _checker.checkUpdate(ozonParams);
      _freefireth = await _freefirethChecker.checkUpdate();
      _roblox = await _robloxChecker.checkUpdate();
      _tiktok = await _tiktokChecker.checkUpdate();
      /* await (
        _checker.checkUpdate(wildberisParams).then((r) => _wildberries = r),
        _checker.checkUpdate(ozonParams).then((r) => _ozon = r),
        _robloxChecker.checkUpdate().then((r) => _roblox = r),
        _tiktokChecker.checkUpdate().then((r) => _tiktok = r),
        _freefirethChecker.checkUpdate().then((r) => _freefireth = r),
      ).wait; */
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
    } finally {
      _updating.value = false;
      dev.log(
        '${(stopwatch..stop()).elapsedMicroseconds / 10000} μs',
        name: 'check_version',
        level: 100,
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
      actions: <Widget>[
        IconButton(
          iconSize: 24,
          padding: EdgeInsets.zero,
          onPressed: () => _checkVersion(refresh: true),
          icon: const Icon(CupertinoIcons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const .all(16),
        child: ValueListenableBuilder(
          valueListenable: _updating,
          builder: (_, updating, _) => FutureBuilder(
            future: _checkVersion(),
            builder: (context, snapshot) {
              // --- Loading state --- //
              if (updating || snapshot.connectionState == .waiting) {
                return Center(
                  child: Row(
                    mainAxisAlignment: .center,
                    spacing: 5,
                    children: <Widget>[
                      const CircularProgressIndicator.adaptive(),
                      Text(updating ? 'Updating...' : 'Loading...'),
                    ],
                  ),
                );
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
                  children: <Widget>[
                    _Section(title: 'Ozon', item: _ozon),
                    _Section(title: 'Willberies', item: _wildberries),
                    _Section(title: 'Roblox', item: _roblox),
                    _Section(title: 'Tik Tok', item: _tiktok),
                    _Section(title: 'Freefeireth', item: _freefireth),
                  ],
                ),
              );
            },
          ),
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
        crossAxisAlignment: .start,
        spacing: 5,
        children: <Widget>[
          Row(
            spacing: 10,
            children: <Widget>[
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: .w600, fontSize: 17),
                ),
              ),
              if (canUpdate) ...[
                Badge(
                  label: const Text('Can update'),
                  textColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGreen,
                    context,
                  ),
                  backgroundColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGreen,
                    context,
                  ).withAlpha(25),
                  padding: const .symmetric(horizontal: 8, vertical: 3),
                ),
              ],
            ],
          ),
          Text(
            item.toString(),
            style: const TextStyle(fontWeight: .normal, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
