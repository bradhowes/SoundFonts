// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class ManagedSoundFontTests: XCTestCase {

//    func testManagedAppStateSingleton() {
//        doWhenCoreDataReady(#function) { _, context in
//            let app = ManagedAppState.get(context: context)
//            let app2 = ManagedAppState.get(context: context)
//            XCTAssertTrue(app === app2)
//        }
//    }
//
//    func testAddSoundFont() {
//        doWhenCoreDataReady(#function) { _, context in
//            XCTAssertEqual(ManagedSoundFont.countRows(in: context), 0)
//            ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            XCTAssertEqual(ManagedSoundFont.countRows(in: context), 1)
//        }
//    }
//
//    func testHideSoundFont() {
//        doWhenCoreDataReady(#function) { _, context in
//            XCTAssertEqual(ManagedSoundFont.countRows(in: context), 0)
//            let sf = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            sf.setVisible(false)
//            XCTAssertTrue(context.saveOrRollback())
//            XCTAssertEqual(ManagedSoundFont.countRows(in: context), 0)
//        }
//    }
//
//    func testFetchSoundFonts() {
//        doWhenCoreDataReady(#function) { testHarness, context in
//            ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            ManagedSoundFont(in: context, config: CoreDataTestData.sf2)
//            ManagedSoundFont(in: context, config: CoreDataTestData.sf3)
//            let fetched: [ManagedSoundFont]? = testHarness.fetchEntities()
//            XCTAssertNotNil(fetched)
//            XCTAssertEqual(fetched?.count, 3)
//            let sf1 = fetched![0]
//            XCTAssertEqual(sf1.name, "one")
//            XCTAssertEqual(sf1.presets.count, 4)
//            let p1 = sf1.presets[0]
//            XCTAssertEqual(p1.displayName, "One")
//            XCTAssertEqual(p1.embeddedName, "One")
//        }
//    }
//
//    func testFavoriteOrderingSingleton() {
//        doWhenCoreDataReady(#function) { _, context in
//            let app = ManagedAppState.get(context: context)
//            XCTAssertEqual(app.favorites.count, 0)
//
//            let sf = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            _ = app.createFavorite(preset: sf.presets[1])
//            XCTAssertEqual(app.favorites.count, 1)
//        }
//    }
//
//    func testAddFavorite() {
//        doWhenCoreDataReady(#function) { _, context in
//            let app = ManagedAppState.get(context: context)
//            XCTAssertEqual(app.favorites.count, 0)
//
//            let sf = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            let preset = sf.presets[1]
//            let fav = app.createFavorite(preset: sf.presets[1])
//            XCTAssertEqual(app.favorites.count, 1)
//
//            XCTAssertEqual(fav.displayName, preset.displayName)
////            XCTAssertEqual(fav.gain, 0.0)
////            XCTAssertEqual(fav.pan, 0.0)
////            XCTAssertEqual(fav.keyboardLowestNote, 35)
//            XCTAssertTrue(preset.hasFavorite)
//            XCTAssertEqual(fav.orderedBy.favorites.count, 1)
//        }
//    }
//
//    func testFavoriteOrdering() {
//        doWhenCoreDataReady(#function) { _, context in
//            let app = ManagedAppState.get(context: context)
//            XCTAssertEqual(app.favorites.count, 0)
//
//            let sf = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
//            let f1 = app.createFavorite(preset: sf.presets[1])
//            XCTAssertEqual(app.favorites.count, 1)
//
//            f1.setName("first")
//            let f2 = app.createFavorite(preset: sf.presets[2])
//
//            f2.setName("second")
//            XCTAssertEqual(app.favorites.count, 2)
//            XCTAssertEqual(app.favorites[0], f1)
//            XCTAssertEqual(app.favorites[1], f2)
//
//            app.move(favorite: f1, to: 1)
//            XCTAssertEqual(app.favorites[0], f2)
//            XCTAssertEqual(app.favorites[0].displayName, "second")
//            XCTAssertEqual(app.favorites[1], f1)
//            XCTAssertEqual(app.favorites[1].displayName, "first")
//
//            app.deleteFavorite(favorite: f1)
//            XCTAssertEqual(app.favorites.count, 1)
//        }
//    }
}
