ROOT := $(shell git rev-parse --show-toplevel)
FLUTTER := $(shell which flutter)
FLUTTER_BIN_DIR := $(shell dirname $(FLUTTER))
FLUTTER_DIR := $(FLUTTER_BIN_DIR:/bin=)
DART := $(FLUTTER_BIN_DIR)/cache/dart-sdk/bin/dart

# Adding a help file: https://gist.github.com/prwhite/8168133#gistcomment-1313022
help: ## This help dialog
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
			IFS=$$'#' ; \
			help_split=($$help_line) ; \
			help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
			help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
			printf "%-30s %s\n" $$help_command $$help_info ; \
	done

.PHONY: analyze
analyze: ## Runs analyze code
	@echo "╠ ANALYZE CODE"
	@dart analyze . || (echo "▓▓ Lint error ▓▓"; exit 1)
	@echo "╠ ANALYZE LIB"
	@flutter analyze lib test || (echo "▓▓ Lint lib error ▓▓"; exit 1)

.PHONY: format
format: ## Runs formating code
	@echo "╠ FORMAT THE CODE"
	@dart format . || (echo "▓▓ Format error ▓▓"; exit 1)
	@echo "╠ CODE FORMATED SUCCESSFULLY"

.PHONY: clean_cache
clean_cache: ## Runs cleaning the pub cache
	@echo "╠ CLEAN PUB CACHE"
	@flutter pub cache repair
	@echo "╠ PUB CACHE CLEANED SUCCESSFULLY"

.PHONY: run_build_runner
run_build_runner: ## Runs generator
	@echo "╠ RUN BUILD RUNNER"
	@dart --disable-analytics && dart run build_runner build --delete-conflicting-outputs

.PHONY: run_unit
run_unit: ## Runs unit tests in only root directory
	@echo "╠ RUNNING TESTS IN ROOT DERICTORY"
	@flutter test --coverage || (echo "▓▓ Error while running tests ▓▓"; exit 1)
	 -o coverage/lcov.info
	genhtml coverage/lcov.info --output=coverage -o coverage/html || (echo "▓▓ Error while running tests ▓▓"; exit 2)
	@echo "╠ TESTS IN THE ROOT DERICTORY PASSED SUCCESSFULLY"