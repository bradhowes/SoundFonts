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
    SoundFontInfoPreset("a", bank: 1, preset: 1),
    SoundFontInfoPreset("b", bank: 1, preset: 2)
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
    SoundFontInfoPreset("aa", bank: 1, preset: 1),
    SoundFontInfoPreset("bb", bank: 1, preset: 2)
  ]
)!
let sfTwo = SoundFont(sfiTwo.embeddedName, soundFontInfo: sfiTwo, resource: sfiTwo.url)

class SoundFontsMock: SubscriptionManager<SoundFontsEvent>, SoundFonts {
  let collection = [sfOne, sfTwo]
  var restored: Bool = false { didSet { self.notify(.restored) } }
  let soundFontNames: [String] = ["One", "Two"]
  let defaultPreset: SoundFontAndPreset? = .init(soundFontKey: sfOne.key, soundFontName: sfOne.displayName, presetIndex: 0, itemName: "an")
  var count: Int { soundFontNames.count }

  func validateCollections(favorites: Favorites, tags: Tags) {}

  func getBy(index: Int) -> SoundFont { collection[index] }

  func firstIndex(of: SoundFont.Key) -> Int? { collection.firstIndex { $0.key == of } }
  func getBy(key: SoundFont.Key) -> SoundFont? { collection.first { $0.key == key } }
  func getBy(soundFontAndPreset: SoundFontAndPreset) -> SoundFont? { getBy(key: soundFontAndPreset.soundFontKey) }
  func resolve(soundFontAndPreset: SoundFontAndPreset) -> Preset? {
    getBy(key: soundFontAndPreset.soundFontKey)?.presets[soundFontAndPreset.presetIndex]
  }

  func filtered(by tag: Tag.Key) -> [SoundFont.Key] { [] }
  func filteredIndex(index: Int, tag: Tag.Key) -> Int { -1 }
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
  func setEffects(soundFontAndPreset: SoundFontAndPreset, delay: DelayConfig?, reverb: ReverbConfig?, chorus: ChorusConfig?) {}
  func reloadEmbeddedInfo(key: SoundFont.Key) {}

  var hasAnyBundled: Bool { false }
  var hasAllBundled: Bool { false }

  func removeBundled() {}
  func restoreBundled() {}
  func exportToLocalDocumentsDirectory() -> (good: Int, total: Int) { (good: 0, total: 0) }
  func importFromLocalDocumentsDirectory() -> (good: Int, total: Int) { (good: 0, total: 0) }
}

class ActivePresetManagerTests: XCTestCase {

  var settings: Settings!
  var soundFonts: SoundFontsMock!
  var selectedSoundFontManager: SelectedSoundFontManager!
  var activePresetManager: ActivePresetManager!

  override func setUp()
  {
    settings = .init(inApp: true, suiteName: "ActivePresetManagerTests")
    settings.remove(key: .lastActivePreset)
    soundFonts = .init()
    selectedSoundFontManager = .init()
    activePresetManager = .init(soundFonts: soundFonts, selectedSoundFontManager: selectedSoundFontManager, settings: settings)
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
    soundFonts.restored = true

    // Now it is the preset
    XCTAssertEqual(activePresetManager.active, .preset(soundFontAndPreset: preset))

    XCTAssertNotNil(activePresetManager.activeSoundFont)
    XCTAssertNotNil(activePresetManager.activePreset)
  }

  func testIgnoreOtherEvents() {
    XCTAssertEqual(activePresetManager.active, .none)
    soundFonts.notify(.presetChanged(font: sfOne, index: 0))
    soundFonts.restored = true
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
    soundFonts.restored = true
    let favorite: Favorite = .init(soundFontAndPreset: soundFonts.defaultPreset!, presetConfig: .init(name: "Hello"), keyboardLowestNote: nil)
    activePresetManager.setActive(favorite: favorite, playSample: false)
    XCTAssertEqual(activePresetManager.activeFavorite, favorite)

    // Same value
    activePresetManager.setActive(favorite: favorite, playSample: false)
  }

  func testRestoreFromSettings() {
    XCTAssertEqual(activePresetManager.active, .none)
    settings.lastActivePreset = ActivePresetKind.preset(soundFontAndPreset: soundFonts.defaultPreset!)
    soundFonts.restored = true
    XCTAssertEqual(activePresetManager.active, .preset(soundFontAndPreset: soundFonts.defaultPreset!))
  }
}