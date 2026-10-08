# flutter_in_store_app_version_checker

[![Pub Version](https://img.shields.io/pub/v/flutter_in_store_app_version_checker?color=blueviolet)](https://pub.dev/packages/flutter_in_store_app_version_checker)
[![Pub Points](https://img.shields.io/pub/points/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![Pub Likes](https://img.shields.io/pub/likes/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker/score)
[![Downloads](https://img.shields.io/pub/dm/flutter_in_store_app_version_checker?logo=dart)](https://pub.dev/packages/flutter_in_store_app_version_checker)
[![codecov](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graph/badge.svg?token=S5CVNZKDAE)](https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker)
[![GitHub stars](https://img.shields.io/github/stars/ziqq/flutter_in_store_app_version_checker?style=social)](https://github.com/ziqq/flutter_in_store_app_version_checker)


## Description

Find out whether a newer version of your app is published on **Google Play**, **RuStore**, **AppGallery**, **ApkPure** or the **Apple App Store** — with one call and no backend.

```dart
final res = await InStoreAppVersionChecker.instance.checkUpdate(
  const InStoreAppVersionCheckerParams(locale: 'en-US'),
);
if (res.canUpdate) showUpdateDialog(res.newVersion, res.appURL);
```


## Features

- 🔍 **One call** — returns the installed version, the store version, the store URL and whether an update is available.
- 🏪 **Google Play, RuStore, AppGallery, ApkPure and App Store** out of the box.
- 🌍 **Regional storefronts** — check the App Store / Google Play for a specific country and language.
- 🧮 **Semver-aware comparison** — pre-releases, build metadata and `1.2` vs `1.2.0` are handled correctly.
- 🪶 **Lightweight** — depends only on `http` and `meta`; installed app metadata is read by the plugin's own native code, no `package_info_plus` required.
- 🧪 **Testable** — inject your own `http.Client`; well covered by unit tests.


## Getting started

### Install

```bash
flutter pub add flutter_in_store_app_version_checker
```

Requirements: Flutter `>=3.44.0`, Dart `>=3.12.0 <4.0.0`.

### Supported platforms

| Platform | Stores                                     |
|----------|--------------------------------------------|
| Android  | Google Play, ApkPure, RuStore, AppGallery  |
| iOS      | Apple App Store                            |

Other platforms (Web, Windows, Linux, macOS) are not supported.


## Examples

### Check for an update

Package name and current version are read from the installed app automatically.

```dart
import 'package:flutter_in_store_app_version_checker/flutter_in_store_app_version_checker.dart';

Future<void> checkForUpdate() async {
  final res = await InStoreAppVersionChecker.instance.checkUpdate(
    const InStoreAppVersionCheckerParams(locale: 'en-US'),
  );

  if (res.isError) {
    debugPrint('Update check failed: ${res.errorMessage}');
    return;
  }

  debugPrint('Current version: ${res.currentVersion}');
  debugPrint('Store version  : ${res.newVersion}');
  debugPrint('Store URL      : ${res.appURL}');
  debugPrint('Can update     : ${res.canUpdate}');
}
```

### Show an update dialog

A typical "new version available" prompt, using [`url_launcher`](https://pub.dev/packages/url_launcher) to open the store page:

```dart
Future<void> showUpdateDialogIfNeeded(BuildContext context) async {
  final res = await InStoreAppVersionChecker.instance.checkUpdate(
    const InStoreAppVersionCheckerParams(locale: 'en-US'),
  );
  if (!context.mounted || res.isError || !res.canUpdate) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Update available'),
      content: Text('Version ${res.newVersion} is available. '
          'You have ${res.currentVersion}.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => launchUrl(Uri.parse(res.appURL!)),
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
```

### Use ApkPure on Android

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'en',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.apkPure,
);
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

### Use RuStore

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'ru-RU',
  packageName: 'ru.beautybox.twa',
  currentVersion: '38.2.0',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.ruStore,
);
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

RuStore identifies public catalog pages by Android package name. The checker
reads `SoftwareApplication.softwareVersion` from the page JSON-LD. Network
restrictions, missing cards, and malformed metadata are returned as errors.

### Use AppGallery for any app

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'ru-RU',
  packageName: 'ru.beautybox.twa',
  storeID: 'C107631977',
  currentVersion: '38.2.0',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
);
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

`packageName` and `storeID` are different identifiers. The package name comes
from the Android application, while AppGallery assigns a listing ID such as
`C107631977`. Store-specific builds may use different Android package names.

This mode supports arbitrary applications, but it uses the same internal,
undocumented web endpoint as the public AppGallery website. Huawei can change
that endpoint or its response format without notice. The checker validates the
returned App ID and, when `packageName` is explicitly supplied, its package.
Endpoint failures and unexpected responses are returned as errors.

### Use AppGallery for the installed app (official SDK)

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'ru-RU',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.appGalleryNative,
);
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

This mode uses Huawei [`AppUpdateClient`](https://developer.huawei.com/consumer/de/doc/HMS-Guides/appgallerykit-upgrade-devguide)
and is the recommended AppGallery option for the installed application. It does
not support arbitrary applications or `packageName` and `currentVersion`
overrides. When Huawei reports no update, the response is successful with
`newVersion == null` and `canUpdate == false`.

Only Huawei's `NO_UPGRADE_INFO` status means no update was found. Connection
errors, failed checks, unknown statuses, and missing upgrade data return errors.
As in the other modes, `canUpdate` compares version names; it does not compare
Android `versionCode` values. Equal version names return `canUpdate == false`.

The plugin includes `com.huawei.hms:appservice:6.16.2.300` and the Huawei Maven
repository. Projects that enforce repositories in `settings.gradle` must also
allow the Huawei repository:

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
    }
}
```

Huawei documents that `checkAppUpdate` checks the AppGallery server even when
the AppGallery client is not installed. The client is still required when the
user proceeds to the AppGallery details and installation flow. See the
[`AppUpdateClient` FAQ](https://developer.huawei.com/consumer/ru/doc/AppGallery-connect-Guides/appgallerykit-update-faq-0000001054802923).

### Check a specific App Store country

```dart
const params = InStoreAppVersionCheckerParams(locale: 'en-AE');
final res = await InStoreAppVersionChecker.instance.checkUpdate(params);
```

This checks the UAE storefront. Choose a region where the app is available — a language alone (`en`) is not an App Store country. See [Store locale](#store-locale).

### Check another app or override the version

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'en-US',
  packageName: 'com.example.app', // bundle ID on iOS
  currentVersion: '1.2.3',
);
```

### Custom HTTP client

```dart
final checker = InStoreAppVersionChecker.instanceFor(
  httpClient: customHTTPClient,
);
final res = await checker.checkUpdate(
  const InStoreAppVersionCheckerParams(locale: 'en-US'),
);
```


## API

Entry point: [`InStoreAppVersionChecker.instance`](lib/src/in_store_app_version_checker.dart), or [`InStoreAppVersionChecker.instanceFor(httpClient: ...)`](lib/src/in_store_app_version_checker.dart) for a custom client.

### Parameters — [`InStoreAppVersionCheckerParams`](lib/src/in_store_app_version_checker_params.dart)

| Parameter        | Type                                       | Description |
|------------------|--------------------------------------------|-------------|
| `locale`         | `String` (required)                        | Store language/region, e.g. `en-US`. See [Store locale](#store-locale). |
| `packageName`    | `String?`                                  | Android package name / iOS bundle ID. Defaults to the installed app. |
| `storeID`        | `String?`                                  | Store listing ID. Required only for AppGallery web checks, e.g. `C107631977`. |
| `currentVersion` | `String?`                                  | Version to compare against. Defaults to the installed app version. |
| `androidStore`   | `InStoreAppVersionCheckerAndroidStoreType` | `googlePlayStore` (default), `apkPure`, `ruStore`, `appGallery` or `appGalleryNative`. |

If `packageName` or `currentVersion` is omitted, it is resolved from the installed app: on Android from the plugin's native implementation, on iOS from the bundle identifier and `CFBundleShortVersionString`. HTTP checks skip the native metadata request when both overrides are supplied. AppGallery native always reads the installed application's metadata and rejects overrides.

`storeID` is separate from `packageName`. It is required only for AppGallery web
checks. AppGallery native checks obtain the installed application identity from
Huawei and ignore `storeID`.

### Response — [`InStoreAppVersionCheckerResponse`](lib/src/in_store_app_version_checker_response.dart)

| Field            | Description |
|------------------|-------------|
| `isSuccess` / `isError` | Whether the lookup succeeded. |
| `currentVersion` | Installed (or overridden) version. |
| `newVersion`     | Version published in the store, or `null` when unavailable. |
| `canUpdate`      | `true` if the store version is newer. |
| `appURL`         | Link to the store page. |
| `errorMessage`, `error`, `stackTrace` | Details for error responses. |


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

<details>
<summary>Locale rules in detail</summary>

Supported regional forms are `language-REGION` and `language-Script-REGION`.
Underscores are accepted as separators; surrounding whitespace and letter case
are normalized. On Google Play, other locale forms are passed through unchanged.
ApkPure and RuStore ignore `locale`. AppGallery web requests use it to localize
the store response, but `storeID` remains the authoritative listing identifier.
AppGallery native checks let Huawei select the locale.

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

</details>


## Error handling

Always check `isError` before using `canUpdate`. A failed lookup with no store
version also returns `canUpdate == false`; that alone does not mean the app is
up to date. An error response may still report `canUpdate == true` if
`newVersion` is greater.

Errors are returned (not thrown) for: invalid parameters, HTTP/network failures,
malformed store data, app not found in the selected storefront, native SDK
failures, and unsupported platforms.

HTTP modes return success only after reading a non-empty version string from
the requested listing. An equal or older store version is still a successful
check with `canUpdate == false`; missing or malformed version data is an error.
Version names are not required to follow strict SemVer. Apple's optional
listing URL remains `null` when absent, rather than the string `"null"`.

An ApkPure listing with an empty or whitespace-only version returns an error
with `newVersion == null` and `canUpdate == false`. Earlier versions could
return `newVersion == ''` for this failure. Treat either value as an unavailable
version when displaying the response; see the [migration guide](MIGRATION.md).

Google Play HTML checks read the application's identified web data, not any
version-like string on the page. This undocumented web structure can change;
unrecognized data and primary HTTP/network failures trigger the existing
third-party PlayStoreApi fallback. If that source also fails or omits the
version, the response is an error with both attempts described.

When the Google Play fallback throws a network or parsing exception, `error`
and `stackTrace` retain the original fallback error and its stack trace.

Apple HTTP errors include the status, original locale, and resolved storefront.
HTTP 400 includes guidance to check the country code. A successful HTTP 200
response with empty results instead reports that the app was not found in that
storefront; check both its bundle ID and regional availability.

Every HTTP request has a 15-second timeout. A Google Play fallback or an
AppGallery web retry can make the total check longer than one request.
AppGallery native has a 15-second SDK timeout that releases the callback, plus
a 20-second Dart bridge safeguard. Timeout failures return error responses.
Concurrent native calls share one in-flight check, including across checker
instances; after success, failure, or timeout the next call starts a new check.

Response equality and `hashCode` include status, versions, listing URL, and
`errorMessage`. The identity of the diagnostic `error` and `stackTrace` objects
is excluded. A success changing to an error therefore notifies a
`ValueNotifier` even when the version fields have not changed.


## Version comparison

<details>
<summary>How versions are compared</summary>

- Build metadata (`+build`) is ignored.
- Trailing zero segments are normalized: `1.2` equals `1.2.0` (no update).
- Release vs pre-release: a release is higher than a pre-release with the same core. `3.1.0-dev.1` to `3.1.0` is an update; the reverse is not.
- Pre-release tokens are compared after the core version; numeric tokens numerically, mixed/alphanumeric tokens token-by-token with numeric-aware ordering.
- Fully non-numeric current vs numeric new → update; fully non-numeric new vs numeric current → no update.
- Whitespace is trimmed and non-alphanumeric symbols are stripped.

See the unit tests in [test/unit](test/unit) for the authoritative behavior.

</details>


## Platform integration notes

- Android uses Flutter 3.44+ built-in Kotlin support.
- AppGallery native checks use Huawei App Service SDK `6.16.2.300`.
- iOS supports both Swift Package Manager (with the required `FlutterFramework` dependency in `Package.swift`) and CocoaPods.


## Migration

See [MIGRATION.md](MIGRATION.md) for upgrade notes, including the Android package rename and the 3.0 API changes. All release notes are in the [Changelog](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/CHANGELOG.md).


## Development

The repository uses [mise](https://mise.jdx.dev/) for pinned SDKs and
[Just](https://just.systems/) for commands, following the same setup as
`tetradka_app`. `mise.toml` is the source of truth and `mise.lock` records
download URLs and checksums. Dart comes from the pinned Flutter SDK; the
package's minimum supported SDK versions remain unchanged.

```sh
mise trust
mise install
mise exec -- just precommit
```

With mise activated in your shell, use plain `just`, `flutter`, and `dart`.
VS Code resolves Flutter through `mise where flutter` without a local FVM path.
See [CONTRIBUTING.md](CONTRIBUTING.md) for native build prerequisites and the
CocoaPods/SPM checks.

Native plugin tests run with `mise exec -- just test-android-native` and, on
macOS, `mise exec -- just test-ios-native`. CI uploads Dart, Kotlin, and Swift
coverage separately to Codecov. The Android suite substitutes the Huawei SDK
client; it does not prove live AppGallery behavior on a physical Huawei device.


## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
If this package saves you time, please ⭐ [star it on GitHub](https://github.com/ziqq/flutter_in_store_app_version_checker) and 👍 like it on [pub.dev](https://pub.dev/packages/flutter_in_store_app_version_checker) — it helps others find it.


## Funding

If you want to support the development of the library:

- [Buy me a coffee](https://www.buymeacoffee.com/ziqq)
- [Subscribe through Boosty](https://boosty.to/ziqq)


## Maintainers

[Anton Ustinoff (ziqq)](https://github.com/ziqq)


## License

[MIT](https://github.com/ziqq/flutter_in_store_app_version_checker/blob/main/LICENSE)


## Coverage

<img src="https://codecov.io/gh/ziqq/flutter_in_store_app_version_checker/graphs/sunburst.svg?token=S5CVNZKDAE" width="375">
