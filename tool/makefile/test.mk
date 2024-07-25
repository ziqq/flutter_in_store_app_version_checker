.PHONY: coverage genhtml test-unit

# Runs get coverage
coverage:
	@lcov --summary coverage/lcov.info

# Runs generage coverage html
genhtml:
	@genhtml coverage/lcov.info -o coverage/html

# Runs unit tests
test-unit:
	@echo "╠ RUNNING UNIT TESTS..."
	@flutter test --coverage || (echo "Error while running tests"; exit 1)
	@genhtml coverage/lcov.info --output=coverage -o coverage/html || (echo "Error while running tests"; exit 2)
	@echo "╠ UNIT TESTS SUCCESSFULLY"

