// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class SoundFontEntityTests: XCTestCase {

    func testAddSoundFont() {
        doWhenCoreDataReady(#function) { cdth, context in
            XCTAssertEqual(try? SoundFontEntity.count(context), 0)
            SoundFontEntity(context: context, config: CoreDataTestData.sf1)
            XCTAssertEqual(try? SoundFontEntity.count(context), 1)
        }
    }

    func testFetchSoundFonts() {
        doWhenCoreDataReady(#function) { cdth, context in
            SoundFontEntity(context: context, config: CoreDataTestData.sf1)
            SoundFontEntity(context: context, config: CoreDataTestData.sf2)
            SoundFontEntity(context: context, config: CoreDataTestData.sf3)
            let soundFonts: [SoundFontEntity]? = cdth.fetchEntities()
            XCTAssertNotNil(soundFonts)
            XCTAssertEqual(soundFonts?.count, 3)
            let sf1 = soundFonts![0]
            XCTAssertEqual(sf1.name, "one")
            XCTAssertEqual(sf1.presets.count, 4)
            let p1 = sf1.presets[0]
            XCTAssertEqual(p1.name, "One")
            XCTAssertEqual(p1.embeddedName, "One")
        }
    }

    func testFavoriteOrderingSingleton() {
        doWhenCoreDataReady(#function) { cdth, context in
            let favs = FavoriteOrdering.get(context: context)
            XCTAssertEqual(favs.count, 0)
            let favs2 = FavoriteOrdering.get(context: context)
            XCTAssertEqual(favs, favs2)

            let sf = SoundFontEntity(context: context, config: CoreDataTestData.sf1)
            _ = favs.create(context: context, preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(favs.count, 1)
            XCTAssertEqual(favs2.count, 1)
        }
    }

    func testAddFavorite() {
        doWhenCoreDataReady(#function) { cdth, context in
            let favs = FavoriteOrdering.get(context: context)
            XCTAssertEqual(favs.count, 0)

            let sf = SoundFontEntity(context: context, config: CoreDataTestData.sf1)
            let preset = sf.presets[1]
            let fav = favs.create(context: context, preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(favs.count, 1)

            XCTAssertEqual(fav.name, preset.name)
            XCTAssertEqual(fav.gain, 0.0)
            XCTAssertEqual(fav.pan, 0.0)
            XCTAssertEqual(fav.keyboardLowestNote, 35)
            XCTAssertTrue(preset.hasFavorite)
            XCTAssertEqual(fav.orderedBy.ordering.count, 1)

            XCTAssertEqual(favs.count, 1)
        }
    }

    func testFavoriteOrdering() {
        doWhenCoreDataReady(#function) { cdth, context in
            let favs = FavoriteOrdering.get(context: context)
            XCTAssertEqual(favs.count, 0)

            let sf = SoundFontEntity(context: context, config: CoreDataTestData.sf1)
            let f1 = favs.create(context: context, preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(favs.count, 1)

            f1.setName("first")
            let f2 = favs.create(context: context, preset: sf.presets[2], keyboardLowestNote: 36)

            f2.setName("second")
            XCTAssertEqual(favs.count, 2)

            XCTAssertEqual(favs.ordering[0], f1)
            XCTAssertEqual(favs.ordering[1], f2)

            favs.move(favorite: f1, to: 1)
            XCTAssertEqual(favs.ordering[0], f2)
            XCTAssertEqual(favs.ordering[0].name, "second")
            XCTAssertEqual(favs.ordering[1], f1)
            XCTAssertEqual(favs.ordering[1].name, "first")

            favs.delete(favorite: f1)

            XCTAssertEqual(favs.count, 1)
        }
    }
}
