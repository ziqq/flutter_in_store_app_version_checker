.PHONY: get-packages-clean format

# Runs getting the packages in root directory and in each package directory and clean cache
get-packages-clean: get_packages clean_cache

# Format code
format:
	@echo "╠ RUN FORMAT THE CODE..."
	@dart format --fix -l 80 . || (echo "Format code error"; exit 1)
	@(dart format --fix -l 80 . || (echo "Format code error"; exit 2))
	@echo "╠ CODE FORMATED SUCCESSFULLY"

# Runs get coverage
coverage:
	@lcov --summary coverage/lcov.info
# Runs generage coverage html
genhtml:
	@genhtml coverage/lcov.info -o coverage/html

