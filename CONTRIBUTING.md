# Contributing rules

Thank you for your help! Before you start, let's take a look at some agreements.


## iOS: testing (CocoaPods and Swift Package Manager)

This plugin supports iOS builds in two integration modes. **Before opening a PR, please verify that the example app builds in both modes:**

### 1 CocoaPods (Podfile)
Uses `example/ios/Podfile`.

```bash
make init-ios-pods
cd example
fvm flutter run
```

Notes:
- `make init-ios-pods` switches Flutter config to disable SPM and ensures `example/ios/Podfile` is active (it may restore it from `_Podfile`).
- If you run `pod install` manually, always run `fvm flutter pub get` in `example/` first (it generates `ios/Flutter/Generated.xcconfig`).

### 2 Swift Package Manager (SPM)
Uses `example/ios/_Podfile` (Podfile is renamed away) and removes Pods artifacts.

```bash
make init-ios-spm
cd example
fvm flutter run
```

Notes:
- Flutter SPM integration is currently experimental. If something fails specifically in SPM mode, include the iOS project files in your report as suggested by Flutter tooling.
- `make init-ios-spm` renames `Podfile -> _Podfile`, cleans Pods (`Pods/`, `Podfile.lock`) and runs `pod deintegrate` (if available) to remove CocoaPods integration artifacts.

### What to include in PR description
- [ ] iOS builds with CocoaPods (`make init-ios-pods`)
- [ ] iOS builds with SwiftPM (`make init-ios-spm`)


## Pull request rules

Make sure that your code:

1.	Does not contain analyzer errors.
2.	Follows a [official style](https://dart.dev/guides/language/effective-dart/style).
3.  Follows the official [style of formatting](https://flutter.dev/docs/development/tools/formatting).
4.	Contains no errors.
5.	New functionality is covered by tests. New functionality passes old tests.
6.	Create example that demonstrate new functionality if it is possible.

## Accepting the changes

After your pull request passes the review code, the project maintainers will merge the changes
into the branch to which the pull request was sent.

## Issues

Feel free to report any issues and bugs.

1.	To report about the problem, create an issue on GitHub.
2.	In the issue add the description of the problem.
3.	Do not forget to mention your development environment, Flutter version, libraries required for
illustration of the problem.
4.	It is necessary to attach the code part that causes an issue or to make a small demo project
that shows the issue.
5.	Attach stack trace so it helps us to deal with the issue.
6.	If the issue is related to graphics, screen recording is required.
