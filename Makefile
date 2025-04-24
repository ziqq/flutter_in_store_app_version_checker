.PHONY: help
help: ## Help dialog
				@echo 'Usage: make <OPTIONS> ... <TARGETS>'
				@echo ''
				@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: doctor
doctor: ## Check fvm flutter doctor
				@fvm flutter doctor

.PHONY: version
version: ## Check fvm flutter version
				@fvm flutter --version


.PHONY: format
format: ## Format code
				@fvm dart format . --set-exit-if-changed --line-length 80 -o none || (echo "¯\_(ツ)_/¯ Format code error"; exit 1)

.PHONY: fix
fix: format ## Fix code
				@fvm dart fix --apply lib

.PHONY: clean-cache
clean-cache: ## Clean the pub cache
				@fvm flutter pub cache repair

.PHONY: clean
clean: ## Clean flutter
				@fvm flutter clean

.PHONY: get
get: ## Get dependencies
				@flutter pub get || (echo "¯\_(ツ)_/¯ Get dependencies error"; exit 1)

.PHONY: analyze
analyze: get format ## Analyze code
				@dart analyze --fatal-infos --fatal-warnings

.PHONY: check
check: analyze ## Check code
				@dart pub global activate pana
				@pana --json --no-warning --line-length 80 > log.pana.json
				@dart pub publish --dry-run

.PHONY: publish
publish: ## Publish package
				@dart pub publish --server=https://pub.dartlang.org || (echo "¯\_(ツ)_/¯ Publish error"; exit 1)

.PHONY: coverage
coverage: ## Runs get coverage
				@lcov --summary coverage/lcov.info

.PHONY: run-genhtml
run-genhtml: ## Runs generage coverage html
				@genhtml coverage/lcov.info -o coverage/html

.PHONY: test-unit
test-unit: ## Runs unit tests
				@flutter test --coverage || (echo "Error while running tests"; exit 1)
				@genhtml coverage/lcov.info --output=coverage -o coverage/html || (echo "Error while running genhtml with coverage"; exit 2)

.PHONY: tag
tag: ## Add a tag to the current commit
	@dart run tool/tag.dart

.PHONY: tag-add
tag-add: ## Make command to add TAG. E.g: make tag-add TAG=v1.0.0
				@if [ -z "$(TAG)" ]; then echo "TAG is not set"; exit 1; fi
				@git tag $(TAG)
				@git push origin $(TAG)

.PHONY: tag-remove
tag-remove: ## Make command to delete TAG. E.g: make tag-delete TAG=v1.0.0
				@if [ -z "$(TAG)" ]; then echo "TAG is not set"; exit 1; fi
				@git tag -d $(TAG)
				@git push origin --delete $(TAG)

.PHONY: build
build: clean analyze test-unit ## Build test apk for android on example apps
				@cd example && fvm flutter clean && fvm flutter pub get && fvm flutter build apk --release && fvm flutter build ios --release --no-codesign
				@cd example_gradle_8 && fvm flutter clean && fvm flutter pub get && fvm flutter build apk --release && fvm flutter build ios --release --no-codesign
