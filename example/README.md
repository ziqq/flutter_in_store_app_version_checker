# Example

## Description
Demonstrates how to use the `flutter_in_store_app_version_checker` package to
check for app updates in supported Android stores and Apple App Store.

On Android, the example checks the public Tetradka listings in RuStore and
AppGallery and invokes the official AppGallery native check for the installed
example application. Each card displays successful results and returned errors
separately.

The native result depends on the installed application and Huawei environment.
Use a Huawei device to verify the complete `AppUpdateClient` flow.
