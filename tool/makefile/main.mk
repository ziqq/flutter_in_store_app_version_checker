.PHONY: doctor version clean-cache clean-and-generate fvm fluttergen l10n build-runner codegen gen upgrade upgrade outdated dependencies locales run-build-runner run-build-runner-watch

# Check fvm flutter doctor
doctor:
	@fvm flutter doctor

# Check fvm flutter version
version:
	@fvm flutter --version


# Clean the pub cache
clean-cache:
	@echo "╠ CLEAN PUB CACHE"
	@fvm flutter pub cache repair
	@echo "╠ PUB CACHE CLEANED SUCCESSFULLY"

# Clean all generated files and run build_runner:build
clean-and-generate: clean build-runner

# Generate assets
fvm fluttergen:
	@echo "╠ RUN FLUTTERGEN..."
	@fvm dart pub global activate fvm flutter_gen
	@fvm fluttergen -c pubspec.yaml || (echo "▓▓ Fluttergen error ▓▓"; exit 1)
	@echo "╠ FLUTTERGEN SUCCESSFULLY"

# Generate localization
l10n:
	@fvm dart pub global activate intl_utils
	@(dart pub global run intl_utils:generate)
	@(fvm flutter gen-l10n --arb-dir lib/src/core/localization --output-dir lib/src/core/localization/generated --template-arb-file intl_ru.arb)

# Generate code
codegen: get fvm fluttergen l10n build_runner format

# Fix code
fix: format
	@fvm dart fix --apply lib

# Generate all
gen: codegen

# Upgrade dependencies
upgrade:
	@echo "╠ RUN UPGRADE DEPENDENCIES..."
	@fvm flutter pub upgrade || (echo "▓▓ Upgrade error ▓▓"; exit 1)
	@echo "╠ DEPENDENCIES UPGRADED SUCCESSFULLY"

# Upgrade to major versions
upgrade-major:
	@echo "╠ RUN UPGRADE DEPENDENCIES TO MAJOR VERSIONS..."
	@fvm flutter pub upgrade --major-versions
	@echo "╠ DEPENDENCIES UPGRADED SUCCESSFULLY"

# Check outdated dependencies
outdated: get
	@fvm flutter pub outdated

# Check outdated dependencies
dependencies: upgrade
	@fvm flutter pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

# Run build_runner:build
build-runner:
	@echo "╠ RUN BUILD RUNNER:BUILD"
	@fvm dart --disable-analytics && dart run build_runner build --delete-conflicting-outputs --release
	@echo "╠ BUILD RUNNER:BUILD SUCCESSFULLY"

# Run build_runner:watch
build-runner-watch:
	@echo "╠ RUN BUILD RUNNER:WATCH"
	@fvm dart --disable-analytics && dart run build_runner watch --delete-conflicting-outputs