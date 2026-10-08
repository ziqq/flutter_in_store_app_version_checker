# Migration guide


## Unreleased

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
automatically after `flutter pub get` and a rebuild. The Dart API and the
method channel name are unchanged.

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
