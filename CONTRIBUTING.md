# Contributing rules

Thank you for your help! Before you start, let's take a look at some agreements.

## Toolchain and validation

Install [mise](https://mise.jdx.dev/getting-started.html), then run:

```sh
mise trust
mise install
mise exec -- just precommit
```

`mise.toml` pins Flutter (including Dart), Java, Just, and macOS Ruby/CocoaPods.
Commit `mise.lock` together with toolchain updates; refresh it with
`mise lock --platform linux-x64,macos-arm64,macos-x64`.
Flutter checksums are read from Google's official release manifests.

With [mise shell activation](https://mise.jdx.dev/cli/activate.html), plain
`just precommit` and `flutter run` use the pinned SDK. Otherwise prefix commands
with `mise exec --`. VS Code uses `mise where flutter` to resolve the SDK.
FVM and Make are no longer required.

`just precommit` resolves package and example dependencies, checks formatting
without modifying files, analyzes package/tool/example code, validates the
publication archive, and runs package unit tests with coverage and example
widget tests. Use `just format` to apply formatting or `just --list` to see all
commands. HTML coverage (`just run-genhtml`) additionally requires system LCOV.

Android builds require the Android SDK and licenses. iOS builds require macOS
and Xcode. These system tools are not installed by mise.
Flutter can prefer Android Studio's bundled JDK over `JAVA_HOME`. To explicitly
select mise's JDK, run `flutter config --jdk-dir "$(mise where java)"`; this
changes your Flutter user configuration, so it is not done automatically.


## iOS: testing (CocoaPods and Swift Package Manager)

This plugin supports iOS builds in two integration modes. **Before opening a PR, please verify that the example app builds in both modes:**

### 1 CocoaPods (Podfile)
Uses `example/ios/Podfile`.

```bash
mise exec -- just init-ios-pods
cd example
mise exec -- flutter run
```

Notes:
- `just init-ios-pods` switches Flutter config to disable SPM and ensures `example/ios/Podfile` is active (it may restore it from `_Podfile`).
- If you run `pod install` manually, always run `mise exec -- flutter pub get` in `example/` first (it generates `ios/Flutter/Generated.xcconfig`).

### 2 Swift Package Manager (SPM)
Uses `example/ios/_Podfile` (Podfile is renamed away) and removes Pods artifacts.

```bash
mise exec -- just init-ios-spm
cd example
mise exec -- flutter run
```

Notes:
- Flutter SPM integration is currently experimental. If something fails specifically in SPM mode, include the iOS project files in your report as suggested by Flutter tooling.
- `just init-ios-spm` renames `Podfile -> _Podfile`, cleans Pods (`Pods/`, `Podfile.lock`) and runs `pod deintegrate` (if available) to remove CocoaPods integration artifacts. Both integration-switching recipes remove existing Pods and their lockfile; commit or save native changes first.

### What to include in PR description
- [ ] Android example builds (`mise exec -- just build-android`)
- [ ] iOS builds with CocoaPods (`just init-ios-pods`, then `just build-ios`)
- [ ] iOS builds with SwiftPM (`just init-ios-spm`, then `just build-ios`)
- [ ] Full local validation passes (`mise exec -- just precommit`)


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
