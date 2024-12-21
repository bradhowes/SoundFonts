// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

// swiftlint:disable force_unwrapping
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
    XCTAssertEqual(soundFont?.displayName, "Dirtelec")
    XCTAssertEqual(soundFont?.embeddedName, "User Define Bank")
    XCTAssertEqual(soundFont?.presets.count, 1)
    XCTAssertEqual(soundFont?.key.uuidString, "00180D06-F33A-4164-A04F-D57CC25B6893")

    let preset = soundFont?.presets[0]
    XCTAssertEqual(preset?.originalName, "Dirty Elec Organ")
    XCTAssertEqual(preset?.soundFontIndex, 0)
    XCTAssertEqual(preset?.bank, 0)
    XCTAssertEqual(preset?.program, 0)

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
    XCTAssertEqual(favorite.soundFontAndPreset.presetIndex, 0)

    let sf = soundFonts.getBy(key: favorite.soundFontAndPreset.soundFontKey)
    XCTAssertNotNil(sf)
    XCTAssertEqual(sf!.displayName, "Evil synclavier")
    let p = sf?.presets[favorite.soundFontAndPreset.presetIndex]
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
    let configProvider = ConsolidatedConfigProvider(inApp: true, fileURL: url, identity: "Foo")

    let waiter = XCTWaiter()
    let expectation = XCTestExpectation(description: "loaded")
    let observer = ConsolidatedConfigObserver(configProvider: configProvider) {
      expectation.fulfill()
    }

    configProvider.load()

    let result = waiter.wait(for: [expectation], timeout: 10.0)
    XCTAssertNotEqual(result, XCTWaiter.Result.timedOut)

    XCTAssertEqual(observer.soundFonts?.count, 6)
    XCTAssertEqual(observer.favorites?.count, 2)
    XCTAssertEqual(observer.tags?.count, 3)
  }

  func testDecodingLegacyConsolidatedFile_V2() {
    let bundle = Bundle(for: type(of: self))
    let url = bundle.url(forResource: "Consolidated_V2", withExtension: "plist")!
    let configProvider = ConsolidatedConfigProvider(inApp: true, fileURL: url, identity: "Foo")

    let waiter = XCTWaiter()
    let expectation = XCTestExpectation(description: "loaded")
    let observer = ConsolidatedConfigObserver(configProvider: configProvider) {
      expectation.fulfill()
    }

    configProvider.load()

    let result = waiter.wait(for: [expectation], timeout: 10.0)
    XCTAssertNotEqual(result, XCTWaiter.Result.timedOut)

    XCTAssertEqual(observer.soundFonts?.count, 4)
    XCTAssertEqual(observer.favorites?.count, 5)
    XCTAssertEqual(observer.tags?.count, 3)

    for index in 0..<observer.favorites!.count {
      let favorite = observer.favorites!.getBy(index: index)
      let soundFont = observer.soundFonts!.getBy(key: favorite.soundFontAndPreset.soundFontKey)
      XCTAssertNotNil(soundFont)
    }

    let soundFonts = SoundFontsManager(configProvider, settings: Settings())
    XCTAssertTrue(soundFonts.isRestored)
    let favorites = FavoritesManager(configProvider)
    XCTAssertTrue(favorites.isRestored)
    let tags = TagsManager(configProvider)
    XCTAssertTrue(tags.isRestored)

    let tag = tags.getBy(index: 0)
    XCTAssertEqual("One", tag?.name)

    let filtered = soundFonts.filtered(by: tag!.key)
    XCTAssertEqual(1, filtered.count)
    let sf = soundFonts.getBy(key: filtered[0])
    XCTAssertNotNil(sf)
    XCTAssertEqual("Fluid R3", sf?.displayName)

    let sfap1 = SoundFontAndPreset(soundFontKey: sf!.key,
                                   soundFontName: sf!.originalDisplayName,
                                   presetIndex: 0,
                                   itemName: sf!.presets[0].originalName)
    let resolved1 = soundFonts.resolve(soundFontAndPreset: sfap1)
    XCTAssertNotNil(resolved1)

    let sfap2 = SoundFontAndPreset(soundFontKey: UUID(),
                                   soundFontName: sf!.originalDisplayName,
                                   presetIndex: 0,
                                   itemName: sf!.presets[0].originalName)
    let resolved2 = soundFonts.resolve(soundFontAndPreset: sfap2)
    XCTAssertNotNil(resolved2)
    XCTAssertTrue(resolved1 === resolved2)
  }
}
// swiftlint:enable force_unwrapping
