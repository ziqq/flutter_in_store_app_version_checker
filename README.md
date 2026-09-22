# flutter_in_store_app_version_checker

[![Pub Version](https://img.shields.io/pub/v/flutter_in_store_app_version_checker?color=blueviolet)](https://pub.dev/packages/flutter_in_store_app_version_checker)
[![popularity](https://img.shields.io/pub/popularity/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![likes](https://img.shields.io/pub/likes/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![codecov](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graph/badge.svg?token=S5CVNZKDAE)](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)

## Description
A lightweight Flutter plugin to check whether your app (or any other app) has a newer version published on Google Play, ApkPure, or Apple App Store.

Minimum supported SDKs:
- Flutter `>=3.44.1`
- Dart `>=3.12.1 <4.0.0`

The plugin uses Flutter 3.44+ built-in Kotlin support on Android and retrieves installed app metadata through its own native method channel. It no longer depends on `package_info_plus`.

Add the dependency:

```yaml
dependencies:
  flutter_in_store_app_version_checker: <current>
```

## Supported platforms

| Platform | Stores                |
|----------|-----------------------|
| Android  | Google Play, ApkPure  |
| iOS      | Apple App Store       |

Other platforms (`Web`, `Windows`, `Linux`, `macOS`, etc.) are not supported.

## Supported Android stores

| Android enum value                                 | Description                    |
|----------------------------------------------------|--------------------------------|
| `InStoreAppVersionCheckerAndroidStoreType.googlePlayStore` | Default Google Play flow       |
| `InStoreAppVersionCheckerAndroidStoreType.apkPure`          | Alternative ApkPure scrape     |

## API Overview
Main access point: [`InStoreAppVersionChecker`](lib/src/in_store_app_version_checker.dart) (singleton: [`InStoreAppVersionChecker.instance`](lib/src/in_store_app_version_checker.dart)) returning [`IInStoreAppVersionChecker`](lib/src/in_store_app_version_checker_interface.dart) implemented by [`InStoreAppVersionChecker`](lib/src/in_store_app_version_checker.dart).

Legacy factory-based API from 2.0.x has been removed. Use [`InStoreAppVersionChecker.instance`](lib/src/in_store_app_version_checker.dart) or [`InStoreAppVersionChecker.instanceFor(...)`](lib/src/in_store_app_version_checker.dart) together with [`InStoreAppVersionCheckerParams`](lib/src/in_store_app_version_checker_params.dart). [`InStoreAppVersionChecker.custom(...)`](lib/src/in_store_app_version_checker.dart) is now deprecated and forwards to `instanceFor(...)`.

Request parameters: [`InStoreAppVersionCheckerParams`](lib/src/in_store_app_version_checker_params.dart)

Response object: [`InStoreAppVersionCheckerResponse`](lib/src/in_store_app_version_checker_response.dart)

Internal installed-app metadata helper: [`AppMetadata`](lib/src/util/app_metadata.dart)

Key response fields:
- `isSuccess` / `isError`
- `currentVersion`
- `newVersion`
- `canUpdate`
- `appURL`
- `errorMessage`

Version comparison logic considers:
- Pre-release tokens (numeric and mixed) after core version comparison.
- Build metadata (`+xyz`) is ignored for equality/update decisions.
- Whitespace trimmed; non-alphanumeric symbols stripped (see tests).
- Mixed alphanumeric pre-release segments compared token-by-token with numeric-aware ordering.


## Store locale

Use one regional `locale` for both platforms, for example `en-US` or `en-AE`.
Google Play uses the complete locale for its `hl` language parameter. On iOS,
the region selects the App Store storefront country; it does not automatically
detect the country of the user's App Store account.

| `locale` | Google Play `hl` | App Store country |
|----------|------------------|-------------------|
| `en-US` | `en-US` | `us` |
| `en_AE` | `en-AE` | `ae` |
| `pt-BR` | `pt-BR` | `br` |
| `zh-Hant-TW` | `zh-Hant-TW` | `tw` |
| `ru` | `ru` | `ru` (legacy country-only input) |
| `en` | `en` | Invalid country; Apple returns an error |

Supported regional forms are `language-REGION` and `language-Script-REGION`.
Underscores are accepted as separators; surrounding whitespace and letter case
are normalized. On Google Play, other locale forms are passed through unchanged.
ApkPure ignores `locale`.

On iOS, existing two-letter country-only values such as `us`, `ae`, and `ru`
remain supported. Short values are interpreted as countries: `ar` means
Argentina, while `ar-AE` explicitly selects the UAE storefront. A language such
as `en` cannot determine a country, and the package never silently falls back
to a different storefront.

iOS rejects malformed values, locales without a country such as `zh-Hant`,
numeric regions such as `es-419`, and locale variants or extensions. This is
structural validation, not a list of supported storefronts: Apple determines
whether the requested country is supported and whether the app is available
there. See Apple's [country parameter documentation](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html).


## Example

### Simple check (Play Store HTML with fallback API)
```dart
import 'dart:developer' as dev;

import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

Future<void> check() async {
  const params = InStoreAppVersionCheckerParams(
    locale: 'en-US',
    // packageName:    'com.example.app', // optional override
    // currentVersion: '1.2.3',           // optional override
    // androidStore:   InStoreAppVersionCheckerAndroidStoreType.apkPure,
  );
  final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
  if (res.isError) {
    dev.log(
      res.errorMessage ?? 'Update check failed',
      error: res.error,
      stackTrace: res.stackTrace,
    );
    return;
  }
  dev.log('Current version: ${res.currentVersion}');
  dev.log('New version    : ${res.newVersion}');
  dev.log('App url        : ${res.appURL}');
  dev.log('Can update     : ${res.canUpdate}');
}
```

### ApkPure
```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'en',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
);
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

### iOS
```dart
const params = InStoreAppVersionCheckerParams(locale: 'en-AE');
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

This explicitly checks the UAE storefront. Choose the region where the app is
available; the English language alone (`en`) is not an App Store country.

### Custom HTTP client
```dart
final checker = InStoreAppVersionChecker.instanceFor(
  httpClient: customHTTPClient,
);
const params = InStoreAppVersionCheckerParams(locale: 'en-US');
final res = await checker.checkUpdate(params);
```

### How package name and version are resolved
If `packageName` or `currentVersion` are not provided in `InStoreAppVersionCheckerParams`, the plugin resolves them from the installed app metadata on the host platform.

- Android: package name and version from the plugin's native Android implementation
- iOS: bundle identifier and `CFBundleShortVersionString` from the plugin's native iOS implementation

This behavior is covered by unit tests in [test/unit/app_metadata_test.dart](test/unit/app_metadata_test.dart).


## Version comparison notes
- Release vs pre-release: a pure release is considered higher than a pre-release with the same core; therefore if current is release and new is pre-release -> treated as update (legacy-compatible).
- Numeric pre-release tokens compared numerically; mixed/alphanumeric tokens compared lexicographically after numeric segments.
- Trailing zero segment normalization: `1.2` equals `1.2.0` (no update).
- Fully non-numeric current vs numeric new => update.
- Fully non-numeric new vs numeric current => no update.
- Build metadata (`+build`) ignored.
See unit tests in [test/unit](test/unit) for authoritative behavior.


## Error handling
Types:
- `success`
- `error` (invalid iOS locale structure, HTTP/network failures, app not found in
  the selected storefront, unsupported platform)

`errorMessage` is populated only for error responses. An error response may still indicate `canUpdate == true` if `newVersion` is greater.

Check `isError` before using `canUpdate`. A failed lookup with no store version
also returns `canUpdate == false`; that alone does not mean the app is up to date.

Apple HTTP errors include the status, original locale, and resolved storefront.
HTTP 400 includes guidance to check the country code. A successful HTTP 200
response with empty results instead reports that the app was not found in that
storefront; check both its bundle ID and regional availability.


## Platform integration notes
- Android example app is migrated to Flutter built-in Kotlin.
- iOS Swift Package Manager support includes the required `FlutterFramework` dependency in `Package.swift`.
- CocoaPods support remains available alongside Swift Package Manager.


## Changelog
Refer to the [Changelog](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/CHANGELOG.md) to get all release notes.


## Maintainers
[Anton Ustinoff (ziqq)](https://github.com/ziqq)


## License
[MIT](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/LICENSE)


## Funding
If you want to support the development of our library, there are several ways you can do it:

- [Buy me a coffee](https://www.buymeacoffee.com/ziqq)
- [Subscribe through Boosty](https://boosty.to/ziqq)


## Coverage
<img  src="https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graphs/sunburst.svg?token=S5CVNZKDAE"  width="375">
