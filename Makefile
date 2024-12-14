PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS
XCCOV = xcrun xccov view --report --only-targets

DEST = -scheme 'iOS App' -destination platform="$(PLATFORM_IOS)"

default: report

build: clean
	xcodebuild -workspace SoundFonts.xcworkspace build-for-testing $(DEST) -resultBundlePath $PWD

test: build
	xcodebuild test-without-building $(DEST) 

test-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	xcodebuild test  \
		-scheme 'iOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES \
		ENABLE_TESTING_SEARCH_PATHS=YES

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
		echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	@echo "-- removing cov.txt percentage.txt"
	@-rm -rf cov.txt percentage.txt WD WD.xcresult
	xcodebuild clean ${DEST}

.PHONY: report percentage-iOS coverage-iOS test-iOS
