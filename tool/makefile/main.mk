.PHONY: doctor version get clean clean-all clean-cache clean-and-generate fluttergen l10n build_runner codegen gen upgrade upgrade outdated dependencies locales run-build-runner run-build-runner-watch

# Check flutter doctor
doctor:
	@flutter doctor

# Check flutter version
version:
	@flutter --version

# Get dependencies
get:
	@echo "╠ GET DEPENDENCIES..."
	@flutter pub get || (echo "▓▓ Get dependencies error ▓▓"; exit 1)
	@echo "╠ DEPENDENCIES GETED SUCCESSFULLY"

# Clean the pub cache
clean-cache:
	@echo "╠ CLEAN PUB CACHE"
	@flutter pub cache repair
	@echo "╠ PUB CACHE CLEANED SUCCESSFULLY"

# Clean all generated files and run build_runner:build
clean-and-generate: clean build-runner

# Generate assets
fluttergen:
	@echo "╠ RUN FLUTTERGEN..."
	@dart pub global activate flutter_gen
	@fluttergen -c pubspec.yaml || (echo "▓▓ Fluttergen error ▓▓"; exit 1)
	@echo "╠ FLUTTERGEN SUCCESSFULLY"

# Generate localization
l10n:
	@dart pub global activate intl_utils
	@(dart pub global run intl_utils:generate)
	@(flutter gen-l10n --arb-dir lib/src/core/localization --output-dir lib/src/core/localization/generated --template-arb-file intl_ru.arb)

# Generate code
codegen: get fluttergen l10n build_runner format

# Fix code
fix: format
	@dart fix --apply lib

# Generate all
gen: codegen

# Upgrade dependencies
upgrade:
	@echo "╠ RUN UPGRADE DEPENDENCIES..."
	@flutter pub upgrade || (echo "▓▓ Upgrade error ▓▓"; exit 1)
	@echo "╠ DEPENDENCIES UPGRADED SUCCESSFULLY"

# Upgrade to major versions
upgrade-major:
	@echo "╠ RUN UPGRADE DEPENDENCIES TO MAJOR VERSIONS..."
	@flutter pub upgrade --major-versions
	@echo "╠ DEPENDENCIES UPGRADED SUCCESSFULLY"

# Check outdated dependencies
outdated: get
	@flutter pub outdated

# Check outdated dependencies
dependencies: upgrade
	@flutter pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

# Runs generate locales
locales:
	@echo "╠ CREATE LOCALES"
	@flutter gen-l10n
	@echo "╠ LOCALES CREATED SUCCESSFULLY"

# Run build_runner:build
build-runner:
	@echo "╠ RUN BUILD RUNNER:BUILD"
	@dart --disable-analytics && dart run build_runner build --delete-conflicting-outputs --release
	@echo "╠ BUILD RUNNER:BUILD SUCCESSFULLY"

# Run build_runner:watch
build-runner-watch:
	@echo "╠ RUN BUILD RUNNER:WATCH"
	@dart --disable-analytics && dart run build_runner watch --delete-conflicting-outputs