[![Pub Version](https://img.shields.io/pub/v/flutter_in_store_app_version_checker?color=blueviolet)](https://pub.dev/packages/flutter_in_store_app_version_checker)
[![popularity](https://img.shields.io/pub/popularity/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![likes](https://img.shields.io/pub/likes/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![codecov](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graph/badge.svg?token=S5CVNZKDAE)](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)



#  flutter_in_store_app_version_checker



##  Description

This package is used to check if your app has a new version on playstore or apple app store. Or you can even check what is the latest version of another app on playstore or apple app store.



 ## Supported platforms

 This package supports checking for app updates only on the following platforms:

 |   Platform   |              Description              |
 |--------------|---------------------------------------|
 | [Android]    | GooglePlay, ApkPure                   |
 | [IOS]        | Apple AppStore                        |

 Other platforms, such as [Web], [Windows], [Linux], etc., are not supported.



## Supported Android Stores

The package supports checking for updates through the following Android stores:

 |             Store              |          Description          |
 |--------------------------------|-------------------------------|
 | [AndroidStore.googlePlayStore] | The default Google Play Store |
 | [AndroidStore.apkPure]         | The alternative ApkPure store |


You can specify the store using the `androidStore` parameter:

```dart
final _checker = InStoreAppVersionChecker(
  androidStore: AndroidStore.apkPure, // Use apkPure instead of Google Play
);
```



##  Installation

Add InStoreAppVersionChecker to your pubspec:

```yaml
dependencies:
  flutter_in_store_app_version_checker:  any  # Or the latest version on Pub
```



##  Example


###  Initialize

```dart
final _checker =  InStoreAppVersionChecker();
```

####  Or

```dart
final _checker =  InStoreAppVersionChecker(
  appId:  'Specify the app id',                    // Optional
  currentVersion:  'Specify the current version',  // Optional
);

```


###  Usage

```dart
@override
void  initState() {
  super.initState();
  checkVersion();
}

Future<void> checkVersion() async {
  final result = await _checker.checkUpdate();
  print('App url         : ${result.appURL}');
  print('Can update      : ${result.canUpdate}');
  print('Current version : ${result.currentVersion}');
  print('New version     : ${result.newVersion}');
  if (result.errorMessage != null) print('Error: ${result.errorMessage}');
};
```

#### The results:

 |             Result             |            Description            |
 |--------------------------------|-----------------------------------|
 | [appURL]                       | The link to the app’s store page  |
 | [canUpdate]                    | `true` if an update is available  |
 | [currentVersion]               | The current version of the app    |
 | [newVersion]                   | The new version if available      |
 | [errorMessage]                 | An error message (if any)         |



###  Use on Apk Pure Store

```dart
final _checker =  InStoreAppVersionChecker(
  appId:  'Specify the app id',
  androidStore:  AndroidStore.apkPure,
);

```



## Changelog

Refer to the [Changelog](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/CHANGELOG.md) to get all release notes.



## Maintainers

[Anton Ustinoff (ziqq)](https://github.com/ziqq)



## License

[MIT](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/LICENSE)



##  Coverage

<img  src="https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graphs/sunburst.svg?token=S5CVNZKDAE"  width="375">