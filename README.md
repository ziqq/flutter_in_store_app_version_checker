# flutter_in_store_app_version_checker

## Description

This package is used to check if your app has a new version on playstore or apple app store. Or you can even check what is the latest version of another app on playstore or apple app store.

## Installation

Add InStoreAppVersionChecker to your pubspec:

```yaml
dependencies:
  flutter_in_store_app_version_checker: any # or the latest version on Pub
```

## Example

```dart
  final _checker = InStoreAppVersionChecker();

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  void checkVersion() async {
    _checker.checkUpdate().then((value) {
      log(value.appURL);         // return the app url
      log(value.canUpdate);      // return true if update is available
      log(value.currentVersion); // return current app version
      log(value.errorMessage);   // return error message if found else it will return null
      log(value.newVersion);     // return the new app version
    });
  }
```
### Or

```dart
  final _checker = InStoreAppVersionChecker(
    appId: 'specify the app id',                   // optional
    currentVersion: 'specify the current version', // optional
  );
...
```

### Use on ApkPure Store

```dart
   final _checker = InStoreAppVersionChecker(
    appId: 'com.zhiliaoapp.musically',
    androidStore: AndroidStore.apkPure,
  );
...
```

