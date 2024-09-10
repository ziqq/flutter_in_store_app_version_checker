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

.PHONY: fix
fix: format ## Fix code
	@fvm dart fix --apply lib

.PHONY: clean-cache
clean-cache: ## Clean the pub cache
	@echo "╠ CLEAN PUB CACHE"
	@fvm flutter pub cache repair
	@echo "╠ PUB CACHE CLEANED SUCCESSFULLY"

.PHONY: get
get: ## Get dependencies
	@echo "╠ RUN GET DEPENDENCIES..."
	@flutter pub get || (echo "▓▓ Get dependencies error ▓▓"; exit 1)
	@echo "╠ DEPENDENCIES GETED SUCCESSFULLY"

.PHONY: analyze
analyze: get format ## Analyze code
	@echo "╠ RUN ANALYZE THE CODE..."
	@dart analyze --fatal-infos --fatal-warnings
	@echo "╠ ANALYZED CODE SUCCESSFULLY"

.PHONY: check
check: analyze ## Check code
	@echo "╠ RUN CECK CODE..."
	@dart pub publish --dry-run
	@dart pub global activate pana
	@pana --json --no-warning --line-length 80 > log.pana.json
	@echo "╠ CECKED CODE SUCCESSFULLY"

.PHONY: publish
publish: ## Publish package
	@echo "╠ RUN PUBLISHING..."
	@dart pub publish --server=https://pub.dartlang.org || (echo "▓▓ Publish error ▓▓"; exit 1)
	@echo "╠ PUBLISH PACKAGE SUCCESSFULLY"

.PHONY: coverage
coverage: ## Runs get coverage
	@lcov --summary coverage/lcov.info

.PHONY: genhtml
genhtml: ## Runs generage coverage html
	@genhtml coverage/lcov.info -o coverage/html

.PHONY: test-unit
test-unit: ## Runs unit tests
	@echo "╠ RUNNING UNIT TESTS..."
	@flutter test --coverage || (echo "Error while running tests"; exit 1)
	@genhtml coverage/lcov.info --output=coverage -o coverage/html || (echo "Error while running tests"; exit 2)
	@echo "╠ UNIT TESTS SUCCESSFULLY"

