set minimum-version := "1.57.0"
set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes.
default:
    @just --list

# Install the pinned toolchain and package/example dependencies.
setup:
    @mise install
    @mise exec -- just get

# Run the full local validation pipeline without rewriting sources.
precommit: get format-check check test-unit test-example

# Run the full validation pipeline.
all: precommit

# Run the full validation pipeline in CI.
ci: precommit

# List available recipes.
help:
    @just --list

# Resolve dependencies in the package and example.
get:
    @flutter pub get
    @cd example && flutter pub get

# Format package, tests, tools, and example sources.
format:
    @dart format --line-length 80 lib/ test/ tool/ example/lib/ example/test/

# Check formatting without changing files.
format-check:
    @dart format --set-exit-if-changed --line-length 80 --output=none lib/ test/ tool/ example/lib/ example/test/

# Apply Dart fixes to the library.
fix: format
    @dart fix --apply lib/

# Analyze the package, tools, tests, and example.
analyze:
    @flutter analyze --no-pub --fatal-warnings --no-fatal-infos lib/ test/ tool/
    @cd example && flutter analyze --no-pub --fatal-warnings --no-fatal-infos lib/ test/

# Analyze sources and validate the publication archive.
check: analyze publish-check

# Validate the package archive without publishing.
publish-check:
    @dart pub publish --dry-run

# Run each package unit suite once, with coverage.
test-unit:
    @flutter test --coverage --no-pub test/

# Run the example widget tests.
test-example:
    @cd example && flutter test --no-pub

# Run Android plugin JVM tests and generate JaCoCo XML/HTML coverage.
test-android-native:
    @cd example && flutter pub get
    @cd example/android && ./gradlew :flutter_in_store_app_version_checker:nativeCoverage --console=plain

# Run iOS plugin XCTest on an available simulator and export Swift coverage.
[macos]
test-ios-native:
    @bash tool/test_ios_native.sh

# Summarize an existing LCOV report (requires lcov).
coverage:
    @lcov --summary coverage/lcov.info

# Generate an HTML coverage report (requires lcov).
run-genhtml:
    @genhtml coverage/lcov.info -o coverage/html

# Show SDK and toolchain versions.
version:
    @mise current
    @flutter --version
    @dart --version
    @just --version

# Show Flutter diagnostics.
doctor:
    @flutter doctor

# Clean package and example build outputs.
clean:
    @flutter clean
    @cd example && flutter clean

# Switch the example to CocoaPods integration.
[macos]
init-ios-pods:
    @flutter config --no-enable-swift-package-manager
    @cd example && flutter clean && flutter pub get
    @cd example/ios && if [ -f _Podfile ] && [ ! -f Podfile ]; then mv _Podfile Podfile; fi
    @cd example/ios && rm -rf -- Pods Podfile.lock && pod install

# Switch the example to Swift Package Manager integration.
[macos]
init-ios-spm:
    @flutter config --enable-swift-package-manager
    @cd example && flutter clean
    @cd example/ios && if [ -f Podfile ]; then mv Podfile _Podfile; fi
    @cd example/ios && rm -rf -- Pods Podfile.lock && (pod deintegrate || true)
    @cd example && flutter pub get

# Build the Android example.
build-android:
    @cd example && flutter pub get && flutter build apk --debug --no-pub

# Build the iOS example using the active integration mode.
[macos]
build-ios:
    @cd example && flutter pub get && flutter build ios --simulator --debug --no-codesign --no-pub

# Build release examples on macOS.
[macos]
build:
    @cd example && flutter pub get && flutter build apk --release --no-pub && flutter build ios --release --no-codesign --no-pub

# Publish the package (maintainers only).
publish:
    @dart pub publish

# Create and push the version tag after the tag tool's validation.
tag:
    @dart run tool/tag.dart

# Create and push an explicitly named tag.
tag-add $tag:
    @git tag -- "$tag"
    @git push origin "refs/tags/$tag"

# Delete an explicitly named local and remote tag.
[confirm("Delete the local and remote tag?")]
tag-remove $tag:
    @git tag -d -- "$tag"
    @git push origin --delete "refs/tags/$tag"
