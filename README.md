[![Pub Version](https://img.shields.io/pub/v/flutter_in_store_app_version_checker?color=blueviolet)](https://pub.dev/packages/flutter_in_store_app_version_checker)
[![popularity](https://img.shields.io/pub/popularity/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![likes](https://img.shields.io/pub/likes/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![codecov](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graph/badge.svg?token=9NB42HWAF2)](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)

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

### Initialize

```dart
final _checker = InStoreAppVersionChecker();
```

#### Or

```dart
final _checker = InStoreAppVersionChecker(
  appId: 'Specify the app id',                   // Optional
  currentVersion: 'Specify the current version', // Optional
);
```

### Usage

```dart
@override
void initState() {
  super.initState();
  checkVersion();
}

void checkVersion() async {
  _checker.checkUpdate().then((value) {
    log(value.appURL);         // Return the app url
    log(value.canUpdate);      // Return true if update is available
    log(value.currentVersion); // Return current app version
    log(value.errorMessage);   // Return error message if found else it will return null
    log(value.newVersion);     // Return the new app version
  });
}
```

### Use on Apk Pure Store

```dart
final _checker = InStoreAppVersionChecker(
  appId: 'Specify the app id',
  androidStore: AndroidStore.apkPure,
);
```

## Coverage
<img src="https://codecov.io/gh/ziqq/flutter_check_box_rounded/graphs/sunburst.svg?token=9NB42HWAF2" width="375">

