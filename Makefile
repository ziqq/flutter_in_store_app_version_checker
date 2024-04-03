include tool/makefile/main.mk
include tool/makefile/pub.mk
include tool/makefile/setup.mk
include tool/makefile/test.mk

# This help dialog
# https://gist.github.com/prwhite/8168133#gistcomment-1313022
.PHONY: help
help:
	@echo "Let's make something good"
	@make -s version
	@echo "Available commands:"
	@awk '/^#/ {comment = substr($$0, 3); next} /^[a-zA-Z_0-9-]+:/ {print $$1 " " comment; comment=""}' $(MAKEFILE_LIST)


