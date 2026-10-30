# Migration guide


## 4.0.1

### AppGallery without the Huawei SDK

The Android plugin no longer depends on Huawei App Service. Its permissions,
including `REQUEST_INSTALL_PACKAGES`, and its R8 warnings no longer reach host
applications. Projects can remove `https://developer.huawei.com/repo/` from
`settings.gradle` if nothing else needs it. The plugin declares
`android.permission.INTERNET`, which the Huawei SDK added before.

`appGallery` no longer requires `storeID`: without it, the checker finds the
listing by the installed package name or the `packageName` override.
`appGalleryNative` is removed from `InStoreAppVersionCheckerAndroidStoreType`.
Replace it with `appGallery`, and remove its case from exhaustive `switch`
statements and expressions:

```dart
const params = InStoreAppVersionCheckerParams(
  locale: 'ru-RU',
  androidStore: InStoreAppVersionCheckerAndroidStoreType.appGallery,
);
```

Unlike `appGalleryNative`, `appGallery` accepts `packageName` and
`currentVersion` overrides and returns the published version even when it is
not newer. An application that is not published in AppGallery returns an
error.


## 4.0.0

### Android store selection

`InStoreAppVersionCheckerAndroidStoreType` adds `ruStore`, `appGallery`, and
`appGalleryNative`. Update exhaustive `switch` statements and expressions to
handle these values when upgrading from `3.0.1`.

AppGallery web checks require the optional `storeID` parameter and use an
undocumented public endpoint. Native checks use Huawei `AppUpdateClient` for
the installed application, do not support `packageName` or `currentVersion`
overrides, and compare version names rather than Android `versionCode` values.

The Android plugin now depends on Huawei App Service `6.16.2.300`, including
when native AppGallery checks are not selected. Projects that enforce
repositories in `settings.gradle` must allow `https://developer.huawei.com/repo/`
in 4.0.0. 4.0.1 removes this dependency.

### ApkPure empty version responses

An ApkPure listing with an empty or whitespace-only version now returns
`newVersion: null` instead of `newVersion: ''`. The response remains an error
with the same `FormatException` and `errorMessage`; `canUpdate` remains `false`.

Treat `null` and an empty string as an unavailable version when displaying
legacy responses. Always check `isError` before deciding whether an update
is available.

### Android package renamed

The Android package, namespace, and Gradle group changed:

| Before | After |
|---|---|
| `com.flutter.instoreappversionchecker` | `dev.ustinoff.instoreappversionchecker` |

The plugin class is now
`dev.ustinoff.instoreappversionchecker.InStoreAppVersionCheckerPlugin`.

**Most apps need no changes.** Flutter registers the plugin through the
generated `GeneratedPluginRegistrant`, which picks up the new package
automatically after `flutter pub get` and a rebuild. The Dart entry points,
`checkUpdate` signature, and method channel name are unchanged.

Update your project only if it refers to the old package directly, for example:

- ProGuard/R8 rules such as `-keep class com.flutter.instoreappversionchecker.** { *; }`;
- manual plugin registration or imports of `InStoreAppVersionCheckerPlugin` in
  Kotlin or Java code;
- Gradle dependency substitutions or exclusions that use the old group.

Replace `com.flutter.instoreappversionchecker` with
`dev.ustinoff.instoreappversionchecker` in those places.


## 3.0.0

The factory-based API from 2.0.x has been removed. Use
`InStoreAppVersionChecker.instance` or `InStoreAppVersionChecker.instanceFor(...)`
together with `InStoreAppVersionCheckerParams`.
`InStoreAppVersionChecker.custom(...)` is deprecated and forwards to
`instanceFor(...)`.
