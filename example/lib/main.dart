// Autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'package:flutter/cupertino.dart';
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late InStoreAppVersionChecker _tikTokChecker;
  String? tikTokValue;

  @override
  void initState() {
    super.initState();
    _tikTokChecker = InStoreAppVersionChecker(
      appId: 'ru.beautybox.twa',
    );

    checkVersion();
  }

  void checkVersion() async {
    Future.wait([
      _tikTokChecker
          .checkUpdate()
          .then((value) => tikTokValue = value.toString()),
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
              const Text(
                "TikTok: (apkPure)",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10.0),
              Text(tikTokValue ?? 'Loading ...'),
            ],
          ),
        ),
      ),
    );
  }
}
