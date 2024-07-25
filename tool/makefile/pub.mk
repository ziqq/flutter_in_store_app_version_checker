.PHONY: get format analyze check publish

# Get dependencies
get:
	@echo "╠ RUN GET DEPENDENCIES..."
	@flutter pub get || (echo "▓▓ Get dependencies error ▓▓"; exit 1)
	@echo "╠ DEPENDENCIES GETED SUCCESSFULLY"

# Format code
format:
	@echo "╠ RUN FORMAT THE CODE..."
	@dart format --fix -l 80 . || (echo "▓▓ Format code error ▓▓"; exit 1)
	@(dart format --fix -l 80 . || (echo "▓▓ Format code error ▓▓"; exit 2))
	@echo "╠ CODE FORMATED SUCCESSFULLY"

# Analyze code
analyze: get format
	@echo "╠ RUN ANALYZE THE CODE..."
	@dart analyze --fatal-infos --fatal-warnings
	@echo "╠ ANALYZED CODE SUCCESSFULLY"

# Check code
check: analyze
	@echo "╠ RUN CECK CODE..."
	@dart pub publish --dry-run
	@dart pub global activate pana
	@pana --json --no-warning --line-length 80 > log.pana.json
	@echo "╠ CECKED CODE SUCCESSFULLY"

# Publish package
publish:
	@echo "╠ RUN PUBLISHING..."
	@dart pub publish --server=https://pub.dartlang.org || (echo "▓▓ Publish error ▓▓"; exit 1)
	@echo "╠ PUBLISH PACKAGE SUCCESSFULLY"