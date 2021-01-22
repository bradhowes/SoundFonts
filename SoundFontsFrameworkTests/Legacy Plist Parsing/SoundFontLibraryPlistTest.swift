// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class SoundFontLibraryPListTest: XCTestCase {

    func testDecodingLegacyConfigurationFiles() {
        let soundFonts: LegacySoundFontCollection = {
            let bundle = Bundle(for: type(of: self))
            let url = bundle.url(forResource: "SoundFontLibrary", withExtension: "plist")!
            let data = try! Data(contentsOf: url)
            return try! PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data)
        }()

        XCTAssertEqual(soundFonts.count, 9)

        let soundFont = soundFonts.getBy(index: 0)
        XCTAssertEqual(soundFont.displayName, "Dirtelec")
        XCTAssertEqual(soundFont.embeddedName, "User Define Bank")
        XCTAssertEqual(soundFont.patches.count, 1)
        XCTAssertEqual(soundFont.key.uuidString, "00180D06-F33A-4164-A04F-D57CC25B6893")

        let patch = soundFont.patches[0]
        XCTAssertEqual(patch.name, "Dirty Elec Organ")
        XCTAssertEqual(patch.soundFontIndex, 0)
        XCTAssertEqual(patch.bank, 0)
        XCTAssertEqual(patch.program, 0)

        let favorites: LegacyFavoriteCollection = {
            let bundle = Bundle(for: type(of: self))
            let url = bundle.url(forResource: "Favorites", withExtension: "plist")!
            let data = try! Data(contentsOf: url)
            return try! PropertyListDecoder().decode(LegacyFavoriteCollection.self, from: data)
        }()

        XCTAssertEqual(favorites.count, 6)

        let favorite = favorites.getBy(index: 0)
        XCTAssertEqual(favorite.name, "Synclavier")
        XCTAssertEqual(favorite.presetConfig.gain, 0.0)
        XCTAssertEqual(favorite.presetConfig.pan, -1.0)
        XCTAssertEqual(favorite.soundFontAndPatch.patchIndex, 0)

        let sf = soundFonts.getBy(key: favorite.soundFontAndPatch.soundFontKey)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.displayName, "Evil synclavier")
        let p = sf?.patches[favorite.soundFontAndPatch.patchIndex]
        XCTAssertNotNil(p)
        XCTAssertEqual(p!.name, "Evil Synclavier")
    }
}
