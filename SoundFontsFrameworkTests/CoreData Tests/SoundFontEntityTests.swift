// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class SoundFontTests: XCTestCase {

    func testAppStateSingleton() {
        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)
            let app2 = AppState.get(context: context)
            XCTAssertTrue(app === app2)
        }
    }

    func testAddSoundFont() {
        doWhenCoreDataReady(#function) { cdth, context in
            XCTAssertEqual(SoundFont.countRows(in: context), 0)
            SoundFont(in: context, config: CoreDataTestData.sf1)
            XCTAssertEqual(SoundFont.countRows(in: context), 1)
        }
    }

    func testHideSoundFont() {
        doWhenCoreDataReady(#function) { cdth, context in
            XCTAssertEqual(SoundFont.countRows(in: context), 0)
            let sf = SoundFont(in: context, config: CoreDataTestData.sf1)
            sf.setVisible(false)
            XCTAssertTrue(context.saveOrRollback())
            XCTAssertEqual(SoundFont.countRows(in: context), 0)
        }
    }

    func testFetchSoundFonts() {
        doWhenCoreDataReady(#function) { cdth, context in
            SoundFont(in: context, config: CoreDataTestData.sf1)
            SoundFont(in: context, config: CoreDataTestData.sf2)
            SoundFont(in: context, config: CoreDataTestData.sf3)
            let fetched: [SoundFont]? = cdth.fetchEntities()
            XCTAssertNotNil(fetched)
            XCTAssertEqual(fetched?.count, 3)
            let sf1 = fetched![0]
            XCTAssertEqual(sf1.name, "one")
            XCTAssertEqual(sf1.presets.count, 4)
            let p1 = sf1.presets[0]
            XCTAssertEqual(p1.name, "One")
            XCTAssertEqual(p1.embeddedName, "One")
        }
    }

    func testFavoriteOrderingSingleton() {
        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)
            XCTAssertEqual(app.favorites.count, 0)

            let sf = SoundFont(in: context, config: CoreDataTestData.sf1)
            _ = app.createFavorite(preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(app.favorites.count, 1)
        }
    }

    func testAddFavorite() {
        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)
            XCTAssertEqual(app.favorites.count, 0)

            let sf = SoundFont(in: context, config: CoreDataTestData.sf1)
            let preset = sf.presets[1]
            let fav = app.createFavorite(preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(app.favorites.count, 1)

            XCTAssertEqual(fav.name, preset.name)
            XCTAssertEqual(fav.gain, 0.0)
            XCTAssertEqual(fav.pan, 0.0)
            XCTAssertEqual(fav.keyboardLowestNote, 35)
            XCTAssertTrue(preset.hasFavorite)
            XCTAssertEqual(fav.orderedBy.favorites.count, 1)
        }
    }

    func testFavoriteOrdering() {
        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)
            XCTAssertEqual(app.favorites.count, 0)

            let sf = SoundFont(in: context, config: CoreDataTestData.sf1)
            let f1 = app.createFavorite(preset: sf.presets[1], keyboardLowestNote: 35)
            XCTAssertEqual(app.favorites.count, 1)

            f1.setName("first")
            let f2 = app.createFavorite(preset: sf.presets[2], keyboardLowestNote: 36)

            f2.setName("second")
            XCTAssertEqual(app.favorites.count, 2)
            XCTAssertEqual(app.favorites[0], f1)
            XCTAssertEqual(app.favorites[1], f2)

            app.move(favorite: f1, to: 1)
            XCTAssertEqual(app.favorites[0], f2)
            XCTAssertEqual(app.favorites[0].name, "second")
            XCTAssertEqual(app.favorites[1], f1)
            XCTAssertEqual(app.favorites[1].name, "first")

            app.deleteFavorite(favorite: f1)
            XCTAssertEqual(app.favorites.count, 1)
        }
    }

    func testSetActivePreset() {
        doWhenCoreDataReady(#function) { cdth, context in
            let app = AppState.get(context: context)
            XCTAssertNil(app.activePreset)
            let sf = SoundFont(in: context, config: CoreDataTestData.sf1)
            app.setActive(preset: sf.presets[3])
            XCTAssertNotNil(app.activePreset)
            XCTAssertEqual("Four", app.activePreset?.name)
            app.setActive(preset: sf.presets[0])
            XCTAssertEqual("One", app.activePreset?.name)

            app.setActive(preset: nil)
            XCTAssertNil(app.activePreset)
        }
    }
}
