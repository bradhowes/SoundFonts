// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class SoundFontLibraryPListTest: XCTestCase {

    func testDecodingSoundFontLibrary() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "SoundFontLibrary", withExtension: "plist")!
        let data = try! Data(contentsOf: url)
        let collection = try! PropertyListDecoder().decode(SoundFontCollection.self, from: data)
        XCTAssertEqual(collection.count, 4)

        let soundFont = collection.getBy(index: 0)
        XCTAssertEqual(soundFont.displayName, "Fluid R3")
        XCTAssertEqual(soundFont.embeddedName, "Fluid R3 GM")
        XCTAssertEqual(soundFont.patches.count, 189)
        XCTAssertEqual(soundFont.key.uuidString, "5F0017BD-33E2-45DD-B4C6-57C5C4466F4D")

        let patch = soundFont.patches[0]
        XCTAssertEqual(patch.name, "Yamaha Grand Piano")
        XCTAssertEqual(patch.soundFontIndex, 0)
        XCTAssertEqual(patch.bank, 0)
        XCTAssertEqual(patch.program, 0)
    }

    func testDecodingFavorites() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "Favorites", withExtension: "plist")!
        let data = try! Data(contentsOf: url)
        let collection = try! PropertyListDecoder().decode(FavoriteCollection.self, from: data)
        XCTAssertEqual(collection.count, 5)

        let favorite = collection.getBy(index: 0)
        XCTAssertEqual(favorite.name, "Nice Pianopppp")
        XCTAssertEqual(favorite.gain, 0.0)
        XCTAssertEqual(favorite.soundFontAndPatch.patchIndex, 0)
    }
}
