PLATFORM_IOS = iOS Simulator,name=iPad mini (6th generation)
PLATFORM_MACOS = macOS

DEST = -scheme 'iOS App' -destination platform="$(PLATFORM_IOS)"

default: test # coverage

build: clean
	xcodebuild -workspace SoundFonts.xcworkspace build-for-testing $(DEST) -resultBundlePath $PWD

test: build
	xcodebuild test-without-building $(DEST) ENABLE_TESTING_SEARCH_PATHS=YES

# Extract coverage info for SoundFonts -- expects defintion of env variable GITHUB_ENV

cov.txt: test
	xcrun xccov view --report --only-targets WD.xcresult > cov.txt
	@cat cov.txt

PATTERN = (SF2Files|SoundFontInfoLib|SoundFontsFramework).framework|SooundFontsApp.app|SoundFonts.appex

percentage.txt: cov.txt
	awk '/$(PATTERN)/ {s+=$$4;++c} END {print s/c;}' < cov.txt > percentage.txt
	@cat percentage.txt

coverage: percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
		echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	@echo "-- removing cov.txt percentage.txt"
	@-rm -rf cov.txt percentage.txt WD WD.xcresult
	xcodebuild clean ${DEST}

.PHONY: build test coverage clean
