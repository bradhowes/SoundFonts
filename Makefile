PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS
XCCOV = xcrun xccov view --report --only-targets

DEST = -scheme 'iOS App' -destination platform="$(PLATFORM_IOS)"

default: report

build: clean
	USE_UNSAFE_FLAGS="1" set -o pipefail && xcodebuild \
		-workspace SoundFonts.xcworkspace build-for-testing $(DEST) -resultBundlePath $PWD \
		| xcbeautify --renderer github-actions

test: build
	xcodebuild test-without-building $(DEST) | xcbeautify --renderer github-actions


test-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	USE_UNSAFE_FLAGS="1" ENABLE_TESTING_SEARCH_PATHS="YES" set -o pipefail && xcodebuild test \
		-scheme 'iOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES \
		| xcbeautify --renderer github-actions

coverage-iOS: test-iOS
	$(XCCOV) $(PWD)/.DerivedData-iOS/Logs/Test/*.xcresult > coverage_iOS.txt
	echo "iOS Coverage:"
	cat coverage_iOS.txt

PATTERN = (SF2Files|SoundFontInfoLib|SoundFontsFramework).framework|SooundFontsApp.app|SoundFonts.appex

percentage-iOS: coverage-iOS
	awk '/$(PATTERN)/ {s+=$$4;++c} END {print s/c;}' coverage_iOS.txt > percentage_iOS.txt
	echo "iOS Coverage Pct:"
	cat percentage_iOS.txt

report: percentage-iOS
	@if [[ -n "$$GITHUB_ENV" ]]; then \
		echo "PERCENTAGE=$$(< percentage_iOS.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	-rm -rf $(PWD)/.DerivedData-iOS coverage*.txt percentage*.txt

.PHONY: report percentage-iOS coverage-iOS test-iOS
