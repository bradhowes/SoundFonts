// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

class ActivePresetKindTests: XCTestCase {

  func testPresetKind() {
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, presetIndex: 1)
    let kind = ActivePresetKind.preset(soundFontAndPreset: soundFontAndPreset)
    XCTAssertEqual(kind.soundFontAndPreset, soundFontAndPreset)
    XCTAssertNil(kind.favorite)

    var data = kind.encodeToData()
    XCTAssertNotNil(data)
    XCTAssertEqual(ActivePresetKind.decodeFromData(data!), kind)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    XCTAssertNoThrow(try encoder.encode(kind))

    data = try? encoder.encode(kind)
    XCTAssertNotNil(data)

    let decoder = JSONDecoder()
    XCTAssertNoThrow(try decoder.decode(ActivePresetKind.self, from: data!))
    let kinder = try? decoder.decode(ActivePresetKind.self, from: data!)
    XCTAssertNotNil(kinder)
    XCTAssertEqual(kind, kinder)

    XCTAssertEqual(kind.description, ".preset(SoundFontAndPreset(soundFontKey: E621E1F8-C36C-495A-93FC-0C247A3E6E5F, patchIndex: 1)")
  }

  func testFavoriteKind() {
    let preset = Preset("foo", 1, 2, 3)
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, presetIndex: 1)
    let favorite = Favorite(soundFontAndPreset: soundFontAndPreset,
                            presetConfig: preset.presetConfig,
                            keyboardLowestNote: Note(midiNoteValue: 64))

    let kind = ActivePresetKind.favorite(favorite: favorite)
    XCTAssertEqual(kind.soundFontAndPreset, soundFontAndPreset)
    XCTAssertEqual(kind.favorite, favorite)

    var data = kind.encodeToData()
    XCTAssertNotNil(data)
    XCTAssertEqual(ActivePresetKind.decodeFromData(data!), kind)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    XCTAssertNoThrow(try encoder.encode(kind))

    data = try? encoder.encode(kind)
    XCTAssertNotNil(data)

    let decoder = JSONDecoder()
    XCTAssertNoThrow(try decoder.decode(ActivePresetKind.self, from: data!))
    let kinder = try? decoder.decode(ActivePresetKind.self, from: data!)
    XCTAssertNotNil(kinder)
    XCTAssertEqual(kind, kinder)

    XCTAssertEqual(kind.description, ".favorite(['foo' - SoundFontAndPreset(soundFontKey: E621E1F8-C36C-495A-93FC-0C247A3E6E5F, patchIndex: 1)])")
  }
}
