// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import SoundFontInfoLib
import SoundFontsFramework
import XCTest

class ManagedAppStateTests: XCTestCase {

  func testSingleton() {
    doWhenCoreDataReady(#function) { _, context in
      let app = ManagedAppState.get(context: context)
      let app2 = ManagedAppState.get(context: context)
      XCTAssertTrue(app === app2)
    }
  }

  func testStockTags() {
    doWhenCoreDataReady(#function) { _, context in
      let app = ManagedAppState.get(context: context)
      XCTAssertEqual(app.allTag.name, "All")
      XCTAssertEqual(app.builtInTag.name, "Built-In")
    }
  }

  func testFetchSoundFontsOrderedByName() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 0)
      ManagedSoundFont(in: context, config: CoreDataTestData.make("Two"))
      ManagedSoundFont(in: context, config: CoreDataTestData.make("Too"))
      ManagedSoundFont(in: context, config: CoreDataTestData.make("To"))
      ManagedSoundFont(in: context, config: CoreDataTestData.make("2"))
      ManagedSoundFont(in: context, config: CoreDataTestData.make("twos"))
      ManagedSoundFont(in: context, config: CoreDataTestData.make("toos"))

      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 6)
      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.builtInTag), 0)

      let fetched: [ManagedSoundFont] = testHarness.fetchEntities()!
      XCTAssertEqual(fetched[0].displayName, "2")
      XCTAssertEqual(fetched[1].displayName, "To")
      XCTAssertEqual(fetched[2].displayName, "Too")
      XCTAssertEqual(fetched[3].displayName, "toos")
      XCTAssertEqual(fetched[4].displayName, "Two")
      XCTAssertEqual(fetched[5].displayName, "twos")
    }
  }

  func testAddSoundFont() {
    doWhenCoreDataReady(#function) { _, context in
      let app = ManagedAppState.get(context: context)
      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 0)
      app.addToSoundFonts(ManagedSoundFont(in: context, config: CoreDataTestData.sf1))
      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 1)
      app.addToSoundFonts(ManagedSoundFont(in: context, config: CoreDataTestData.sf2))
      XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 2)
      XCTAssertEqual(app.soundFontsSet.count, 2)
    }
  }

  func testRemoveSoundFont() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      app.addToSoundFonts(ManagedSoundFont(in: context, config: CoreDataTestData.sf1))
      app.addToSoundFonts(ManagedSoundFont(in: context, config: CoreDataTestData.sf2))
      XCTAssertEqual(app.soundFontsSet.count, 2)

      let sf1 = app.soundFontsSet.first
      XCTAssertNotNil(sf1)

      context.delete(sf1!)
      try! context.save()

      XCTAssertEqual(app.soundFontsSet.count, 1)
      let fetched: [ManagedSoundFont] = testHarness.fetchEntities()!
      XCTAssertEqual(fetched.count, 1)
    }
  }

  func testAddTags() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      app.addToTags(ManagedTag(in: context, name: "first"))
      app.addToTags(ManagedTag(in: context, name: "second"))
      XCTAssertEqual(app.tagsCollection.count, 4)
      XCTAssertEqual(ManagedTag.countRows(in: context), 4)
    }
  }

  func testRemoveTag() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      app.addToTags(ManagedTag(in: context, name: "first"))
      app.addToTags(ManagedTag(in: context, name: "second"))
      XCTAssertEqual(app.tagsCollection.count, 4)
      let tag = app.tagsCollection[2]

      app.addToSoundFonts(ManagedSoundFont(in: context, config: CoreDataTestData.sf2))
      let sf1 = app.soundFontsSet.first!
      XCTAssertEqual(sf1.tagsSet.count, 1)

      sf1.addToTags(tag)
      XCTAssertEqual(sf1.tagsSet.count, 2)
      XCTAssertEqual(tag.tagged.count, 1)

      context.delete(tag)
      try! context.save()

      XCTAssertEqual(app.tagsCollection.count, 3)
      let fetched: [ManagedTag] = testHarness.fetchEntities()!
      XCTAssertEqual(fetched.count, 3)
      XCTAssertEqual(sf1.tagsSet.count, 1)
    }
  }

  func testReorderTags() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      app.addToTags(ManagedTag(in: context, name: "first"))
      app.addToTags(ManagedTag(in: context, name: "second"))
      app.addToTags(ManagedTag(in: context, name: "third"))
      app.addToTags(ManagedTag(in: context, name: "fourth"))
      XCTAssertEqual(app.tagsCollection.count, 6)
      var tag = app.tagsCollection[2]
      app.removeFromTags(at: 2)
      app.insertIntoTags(tag, at: 3)
      XCTAssertEqual(app.tagsCollection.count, 6)
      tag = app.tagsCollection[2]
      XCTAssertEqual(tag.name, "second")
      tag = app.tagsCollection[3]
      XCTAssertEqual(tag.name, "first")
    }
  }

  func testAddFavorites() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      let sf1 = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
      app.addToSoundFonts(sf1)
      let preset1 = sf1.presetsCollection[0]
      app.addToFavorites(ManagedFavorite(in: context, preset: preset1))
      app.addToFavorites(ManagedFavorite(in: context, preset: preset1))
      XCTAssertEqual(app.favoritesCollection.count, 2)
      XCTAssertEqual(ManagedFavorite.countRows(in: context), 2)
      XCTAssertEqual(preset1.aliases.count, 2)
    }
  }

  func testRemoveFavorites() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      let sf1 = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
      app.addToSoundFonts(sf1)
      let preset1 = sf1.presetsCollection[0]
      app.addToFavorites(ManagedFavorite(in: context, preset: preset1))
      app.addToFavorites(ManagedFavorite(in: context, preset: preset1))
      XCTAssertEqual(app.favoritesCollection.count, 2)

      let favorite1 = app.favoritesCollection[0]
      context.delete(favorite1)
      try! context.save()

      XCTAssertEqual(app.favoritesCollection.count, 1)
      let fetched: [ManagedFavorite] = testHarness.fetchEntities()!
      XCTAssertEqual(fetched.count, 1)
      XCTAssertEqual(preset1.aliases.count, 1)
    }
  }

  func testReorderFavorites() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let app = ManagedAppState.get(context: context)
      let sf1 = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
      app.addToSoundFonts(sf1)
      let preset1 = sf1.presetsCollection[0]
      let favorite1 = ManagedFavorite(in: context, preset: preset1)
      favorite1.displayName = "Cookies"
      app.addToFavorites(favorite1)
      let favorite2 = ManagedFavorite(in: context, preset: preset1)
      favorite2.displayName = "Cream"
      app.addToFavorites(favorite2)

      var fav = app.favoritesCollection[0]
      app.removeFromFavorites(at: 0)
      app.insertIntoFavorites(fav, at: 1)
      XCTAssertEqual(app.favoritesCollection.count, 2)
      XCTAssertEqual(app.favoritesCollection.count, 2)

      fav = app.favoritesCollection[0]
      XCTAssertEqual(fav.displayName, "Cream")
      fav = app.favoritesCollection[1]
      XCTAssertEqual(fav.displayName, "Cookies")
    }
  }
}
