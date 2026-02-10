# Changelog

## 2.0.0-pre.18
- **DEPRECATED**: Legacy facade `InStoreAppVersionChecker` will be removed in next releases
- **ADDED**: New interface `IInStoreAppVersionChecker` (singleton `InStoreAppVersionChecker.instance`)
- **ADDED**: Fallback to public PlayStore API on HTML parsing failure
- **ADDED**: Response fields: `isSuccess`, `isError`, `canUpdate`, improved error messages
- **ADDED**: Extended version comparison logic (pre-release, normalization, ignoring build metadata)
- **ADDED**: Support for `iOS` builds with `Swift Package Manager` and `CocoaPods` (see [CONTRIBUTING.md](CONTRIBUTING.md#ios-testing-cocoapods-and-swift-package-manager))
- **CHANGED**: Updated documentation to reflect new interface and singleton usage
- **CHANGED**: Refactoring legacy facade to use new implementation as delegate
- **CHANGED**: Improved error handling (stack return, format unification)
- **CHANGED**: Migration to a singleton instead of manual creation
- **CHANGED**: Bump dependencies

## 1.11.0
- **FIXED**: `canUpdate` returns allways false on Android, [#11](https://github.com/ziqq/flutter_in_store_app_version_checker/issues/11)

## 1.10.1
- **CHANGED**: Bump dependencies

## 1.10.0
- **ADDED**: Prevent cache hit on iOS (and Android) [pull_request](https://github.com/ziqq/flutter_in_store_app_version_checker/pull/9)
- **CHANGED**: Bump dependencies


## 1.9.0
- **ADDED**: `stackTrace` to [InStoreAppVersionCheckerResult]
- **CHANGED**: parametrs of [InStoreAppVersionCheckerResult] to named
- **CHANGED**: Android package name [#7](https://github.com/ziqq/flutter_in_store_app_version_checker/issues/7)


## 1.8.0
- **ADDED**: `namespace` to android build.gradle


## 1.7.1
- **ADDED**: `package_info_plus`
- **REMOVED**: `pubspec_generator`


## 1.7.0
- **ADDED**: `pubspec_generator`
- **REMOVED**: `package_info_plus`


## 1.6.2
- **ADDED**: `fvm`
- **CHANGED**: `analysis_options`
- **CHANGED**: `.github` configs
- **CHANGED**: bump dependencies


## 1.6.1
- **CHANGED**: bump dependencies


## 1.6.0
- **FIXED**: architecture


## 1.5.1
- **CHANGED**: bump dependencies


## 1.5.0
- **ADDED**: `tests`
- **CHANGED**: Check `platform`


## 1.4.4
- **ADDED**: `tests`
- **CHANGED**: bump `http`


## 1.4.3
 - **CHANGED**: bump `package_info_plus`


## 1.4.2
- **FIXED**: bugs


## 1.4.1
- **FIXED**: bugs


## 1.4.0
- **ADDED**: GeneratedPluginRegistrant


## 1.3.1
- **CHANGED**: bump dependencies


## 1.3.0
- **ADDED**: Check on Web platform


## 1.2.0
- **ADDED**: AppStore default locale


## 1.1.0
- **ADDED**: iOS initial functionality


## 1.0.0
- **ADDED**: Initial functionality