// Autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'dart:io' as io;

import 'package:flutter/cupertino.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final InStoreAppVersionChecker _tikTokChecker;
  late final InStoreAppVersionChecker _tetradkaChecker;

  String? tikTokValue;
  String? tetradkaValue;

  @override
  void initState() {
    super.initState();
    _tetradkaChecker = InStoreAppVersionChecker(
      appId: 'ru.beautybox.twa',
    );
    _tikTokChecker = InStoreAppVersionChecker(
      appId: 'com.zhiliaoapp.musically',
      androidStore: AndroidStore.apkPure,
    );
    _checkVersion();
  }

  void _checkVersion() async {
    Future.wait([
      _tikTokChecker
          .checkUpdate()
          .then((value) => tikTokValue = value.toString()),
      _tetradkaChecker
          .checkUpdate()
          .then((value) => tetradkaValue = value.toString()),
    ]).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('In Store App Version Checker Example'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if (io.Platform.isAndroid) ...[
                const Text(
                  "Tetradka (beauty box)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10.0),
                Text(tetradkaValue ?? 'Loading...'),
              ] else ...[
                const Text(
                  "TikTok: (apkPure)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10.0),
                Text(tikTokValue ?? 'Loading...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
