// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class SoundFontLibraryPListTest: XCTestCase {

  func testDecodingLegacyConfigurationFiles() {
    let soundFonts: SoundFontCollection = {
      let bundle = Bundle(for: type(of: self))
      let url = bundle.url(forResource: "SoundFontLibrary", withExtension: "plist")!
      let data = try! Data(contentsOf: url)
      return try! PropertyListDecoder().decode(SoundFontCollection.self, from: data)
    }()

    XCTAssertEqual(soundFonts.count, 9)

    let soundFont = soundFonts.getBy(index: 0)
    XCTAssertEqual(soundFont.displayName, "Dirtelec")
    XCTAssertEqual(soundFont.embeddedName, "User Define Bank")
    XCTAssertEqual(soundFont.presets.count, 1)
    XCTAssertEqual(soundFont.key.uuidString, "00180D06-F33A-4164-A04F-D57CC25B6893")

    let patch = soundFont.presets[0]
    XCTAssertEqual(patch.originalName, "Dirty Elec Organ")
    XCTAssertEqual(patch.soundFontIndex, 0)
    XCTAssertEqual(patch.bank, 0)
    XCTAssertEqual(patch.program, 0)

    let favorites: FavoriteCollection = {
      let bundle = Bundle(for: type(of: self))
      let url = bundle.url(forResource: "Favorites", withExtension: "plist")!
      let data = try! Data(contentsOf: url)
      return try! PropertyListDecoder().decode(FavoriteCollection.self, from: data)
    }()

    XCTAssertEqual(favorites.count, 6)

    let favorite = favorites.getBy(index: 0)
    XCTAssertEqual(favorite.presetConfig.name, "Synclavier")
    XCTAssertEqual(favorite.presetConfig.gain, 0.0)
    XCTAssertEqual(favorite.presetConfig.pan, -1.0)
    XCTAssertEqual(favorite.soundFontAndPreset.patchIndex, 0)

    let sf = soundFonts.getBy(key: favorite.soundFontAndPreset.soundFontKey)
    XCTAssertNotNil(sf)
    XCTAssertEqual(sf!.displayName, "Evil synclavier")
    let p = sf?.presets[favorite.soundFontAndPreset.patchIndex]
    XCTAssertNotNil(p)
    XCTAssertEqual(p!.originalName, "Evil Synclavier")
  }

  // Make sure that we can always restore from a legacy consolidated file. If a future file format changes, duplicate
  // this test and rename, capture a Consolidated.plist file from a SoundFontsApp via the "export" option, and add to
  // this test bundle so it can be referenced in the test.
  //
  func testDecodingLegacyConsolidatedFile_V1() {
    let bundle = Bundle(for: type(of: self))
    let url = bundle.url(forResource: "Consolidated_V1", withExtension: "plist")!
    let configFile = ConsolidatedConfigFile(fileURL: url)

    let waiter = XCTWaiter()
    let expectation = XCTestExpectation(description: "loaded")
    let observer = ConfigFileObserver(configFile: configFile) {
      expectation.fulfill()
    }
    configFile.load()

    let result = waiter.wait(for: [expectation], timeout: 10.0)
    XCTAssertNotEqual(result, XCTWaiter.Result.timedOut)

    XCTAssertEqual(observer.soundFonts.count, 6)
    XCTAssertEqual(observer.favorites.count, 2)
    XCTAssertEqual(observer.tags.count, 3)
  }
}
