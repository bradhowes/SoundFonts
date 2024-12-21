// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import SoundFontInfoLib
import XCTest

private let suiteName = "ActivePresetManagerTests"

let sfiOne = SoundFontInfo(
  "One",
  url: URL(fileURLWithPath: "/a/b/c"),
  author: "author",
  comment: "comment",
  copyright: "copyright",
  presets: [
    SoundFontInfoPreset("a", bank: 1, program: 1),
    SoundFontInfoPreset("b", bank: 1, program: 2)
  ]
)!
let sfOne = SoundFont(sfiOne.embeddedName, soundFontInfo: sfiOne, resource: sfiOne.url)

let sfiTwo = SoundFontInfo(
  "Two",
  url: URL(fileURLWithPath: "/a/b/c"),
  author: "author",
  comment: "comment",
  copyright: "copyright",
  presets: [
    SoundFontInfoPreset("aa", bank: 1, program: 1),
    SoundFontInfoPreset("bb", bank: 1, program: 2)
  ]
)!
let sfTwo = SoundFont(sfiTwo.embeddedName, soundFontInfo: sfiTwo, resource: sfiTwo.url)

class SoundFontsMock: SubscriptionManager<SoundFontsEvent>, SoundFontsProvider {
  let collection = [sfOne, sfTwo]
  var isRestored: Bool = false { didSet { notify(.restored) } }
  let soundFontNames: [String] = ["One", "Two"]
  let defaultPreset: SoundFontAndPreset? = .init(soundFontKey: sfOne.key, soundFontName: sfOne.displayName, presetIndex: 0, itemName: "an")
  var count: Int { soundFontNames.count }
  var isEmpty: Bool { count == 0 }
  
  func validateCollections(favorites: FavoritesProvider, tags: TagsProvider) {}

  func getBy(index: Int) -> SoundFont? { collection[index] }

  func firstIndex(of: SoundFont.Key) -> Int? { collection.firstIndex { $0.key == of } }
  func getBy(key: SoundFont.Key) -> SoundFont? { collection.first { $0.key == key } }
  func getBy(soundFontAndPreset: SoundFontAndPreset) -> SoundFont? { getBy(key: soundFontAndPreset.soundFontKey) }
  func resolve(soundFontAndPreset: SoundFontAndPreset) -> Preset? {
    getBy(key: soundFontAndPreset.soundFontKey)?.presets[soundFontAndPreset.presetIndex]
  }

  func filtered(by tag: Tag.Key) -> [SoundFont.Key] { [] }
  func indexFilteredByTag(index: Int, tag: Tag.Key) -> Int { -1 }
  func names(of keys: [SoundFont.Key]) -> [String] { [] }
  func add(url: URL) -> Result<(Int, SoundFont), SoundFontFileLoadFailure> { .failure(.invalidFile("blah")) }
  func remove(key: SoundFont.Key) {}
  func rename(key: SoundFont.Key, name: String) {}
  func removeTag(_ tag: Tag.Key) {}
  func createFavorite(soundFontAndPreset: SoundFontAndPreset, keyboardLowestNote: Note?) -> Favorite? { nil }
  func deleteFavorite(soundFontAndPreset: SoundFontAndPreset, key: Favorite.Key) {}
  func updatePreset(soundFontAndPreset: SoundFontAndPreset, config: PresetConfig) {}
  func setVisibility(soundFontAndPreset: SoundFontAndPreset, state: Bool) {}
  func makeAllVisible(key: SoundFont.Key) {}
  func setEffects(soundFontAndPreset: SoundFontAndPreset, delay: DelayConfig?, reverb: ReverbConfig?) {}
  func reloadEmbeddedInfo(key: SoundFont.Key) {}

  var hasAnyBundled: Bool { false }
  var hasAllBundled: Bool { false }

  func removeBundled() {}
  func restoreBundled() {}
  func exportToLocalDocumentsDirectory() -> (good: Int, total: Int) { (good: 0, total: 0) }
  func importFromLocalDocumentsDirectory() -> (good: Int, total: Int) { (good: 0, total: 0) }
}

class FavoritesMock: SubscriptionManager<FavoritesEvent>, FavoritesProvider {
  var favorites: [Favorite] = .init()
  var isRestored: Bool = false { didSet { notify(.restored) } }
  var count: Int { favorites.count }
  func contains(key: Favorite.Key) -> Bool { false }
  func index(of favorite: Favorite.Key) -> Int? { fatalError() }
  func getBy(index: Int) -> Favorite? { fatalError() }
  func getBy(key: Favorite.Key) -> Favorite? { favorites[0] }
  func add(favorite: Favorite) { fatalError() }
  func beginEdit(config: FavoriteEditor.Config) { fatalError() }
  func update(index: Int, config: PresetConfig) { fatalError() }
  func move(from: Int, to: Int) { fatalError() }
  func setVisibility(key: Favorite.Key, state: Bool) { fatalError() }
  func setEffects(favorite: Favorite, delay: DelayConfig?, reverb: ReverbConfig?) { fatalError() }
  func selected(index: Int) { fatalError() }
  func remove(key: Favorite.Key) { fatalError() }
  func removeAll(associatedWith: SoundFont) { fatalError() }
  func count(associatedWith: SoundFont) -> Int { 0 }
  func validate(_ soundFonts: SoundFontsProvider) {}
}

class ActivePresetManagerTests: XCTestCase {

  var settings: Settings!
  var soundFonts: SoundFontsMock!
  var favorites: FavoritesMock!
  var selectedSoundFontManager: SelectedSoundFontManager!
  var activePresetManager: ActivePresetManager!

  override func setUp()
  {
    settings = .init(suiteName: "ActivePresetManagerTests")
    settings.remove(key: .lastActivePreset)
    soundFonts = .init()
    favorites = .init()

    favorites.favorites.append(.init(soundFontAndPreset: soundFonts.defaultPreset!, presetConfig: .init(name: "Hello"),
                                     keyboardLowestNote: nil))

    selectedSoundFontManager = .init()
    activePresetManager = .init(soundFonts: soundFonts, favorites: favorites, selectedSoundFontManager: selectedSoundFontManager, settings: settings)
  }

  func testInitialState() {
    XCTAssertEqual(activePresetManager.active, .none)
    XCTAssertNil(activePresetManager.activeSoundFont)
    XCTAssertNil(activePresetManager.activePreset)
    XCTAssertNil(activePresetManager.activeFavorite)
    XCTAssertNil(activePresetManager.activePresetConfig)
  }

  func testSetActiveBeforeRestoration() {
    let preset = soundFonts.defaultPreset!

    // Remembers the set but does not make it active yet
    activePresetManager.setActive(preset: preset, playSample: false)
    XCTAssertEqual(activePresetManager.active, .none)

    // Receive restoration signal
    soundFonts.isRestored = true
    favorites.isRestored = true

    // Now it is the preset
    XCTAssertEqual(activePresetManager.active, .none)
  }

  func testRestoreActiveBeforeRestoration() {
    let preset = soundFonts.defaultPreset!

    // Remembers the set but does not make it active yet
    XCTAssertEqual(activePresetManager.state, .starting)
    activePresetManager.restoreActive(.preset(soundFontAndPreset: preset))

    XCTAssertEqual(activePresetManager.state, .pending(.preset(soundFontAndPreset: preset)))
    XCTAssertEqual(activePresetManager.active, .none)

    // Receive restoration signal, but no change in state
    soundFonts.isRestored = true
    XCTAssertEqual(activePresetManager.state, .pending(.preset(soundFontAndPreset: preset)))
    XCTAssertEqual(activePresetManager.active, .none)

    // Listen for notification from activePresetManager
    let expectation = expectation(description: "received active preset notification")
    activePresetManager.subscribe(self) { _ in
      expectation.fulfill()
    }

    // Receive notification signal, and wait for event from activePresetManager
    favorites.isRestored = true
    wait(for: [expectation], timeout: 60.0)

    XCTAssertEqual(activePresetManager.state, .normal)

    // Now it is the preset
    XCTAssertEqual(activePresetManager.active, .preset(soundFontAndPreset: preset))
    XCTAssertNotNil(activePresetManager.activeSoundFont)
    XCTAssertNotNil(activePresetManager.activePreset)
  }

  func testIgnoreOtherEvents() {
    XCTAssertEqual(activePresetManager.active, .none)
    soundFonts.notify(.presetChanged(font: sfOne, index: 0))
    soundFonts.isRestored = true
    favorites.isRestored = true
  }

  func testResolveToSoundFont() {
    let soundFont: SoundFont! = activePresetManager.resolveToSoundFont(soundFonts.defaultPreset!)
    XCTAssertNotNil(soundFont)
    XCTAssertEqual(soundFont.displayName, "One")
  }

  func testResolveToPreset() {
    let preset: Preset! = activePresetManager.resolveToPreset(soundFonts.defaultPreset!)
    XCTAssertNotNil(preset)
  }

  func testSetFavorite() {
    let expectation1 = XCTestExpectation(description: "setup")
    activePresetManager.subscribe(self) { _ in
      expectation1.fulfill()
    }

    soundFonts.isRestored = true
    favorites.isRestored = true

    wait(for: [expectation1], timeout: 0.2)

    let favorite: Favorite = favorites.favorites[0]
    activePresetManager.setActive(favorite: favorite, playSample: false)
    XCTAssertEqual(activePresetManager.activeFavorite, favorite)

    activePresetManager.setActive(favorite: favorite, playSample: false)
  }
}
