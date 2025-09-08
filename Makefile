.PHONY: format

format:
	swift run -c release --package-path BuildTools swiftformat --config BuildTools/.swiftformat .