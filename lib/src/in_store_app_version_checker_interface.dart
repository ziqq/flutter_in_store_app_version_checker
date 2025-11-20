/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 28 October 2025
 */

import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_params.dart';
import 'package:flutter_in_store_app_version_checker/src/in_store_app_version_checker_response.dart';

/// {@template in_store_app_version_checker_interface}
/// [IInStoreAppVersionChecker] is an interface for checking the current version
/// of an app available in app stores such as `AppStore`, `Google Play`
/// and `ApkPure`, comparing it with the installed version on the device.
/// It supports both `Android` and `iOS` platforms.
///
/// Methods:
/// - `checkUpdate()`: Checks for app updates in the selected app store.
///
/// This class simplifies the process of checking for app updates by automating API
/// requests to app stores and is compatible with popular mobile platforms.
/// {@endtemplate}
abstract interface class IInStoreAppVersionChecker {
  /// Check on update app in store with given [params].
  Future<InStoreAppVersionChecker$Response> checkUpdate(
    InStoreAppVersionChecker$Params params,
  );
}
