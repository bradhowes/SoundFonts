// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class ActivePresetKindTests: XCTestCase {

  func testPresetKind() {
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
                                                presetIndex: 1, name: "Foo")
    let kind = ActivePresetKind.preset(soundFontAndPreset: soundFontAndPreset)
    XCTAssertEqual(kind.soundFontAndPreset, soundFontAndPreset)
    XCTAssertNil(kind.favorite)

    let dictData = kind.encodeToDict()
    XCTAssertNotNil(dictData)
    XCTAssertEqual(ActivePresetKind.decodeFromDict(dictData!), kind)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    XCTAssertNoThrow(try encoder.encode(kind))

    let json = try? encoder.encode(kind)
    XCTAssertNotNil(json)

    let decoder = JSONDecoder()
    XCTAssertNoThrow(try decoder.decode(ActivePresetKind.self, from: json!))
    let kinder = try? decoder.decode(ActivePresetKind.self, from: json!)
    XCTAssertNotNil(kinder)
    XCTAssertEqual(kind, kinder)

    XCTAssertEqual(kind.description, ".preset([E621E1F8-C36C-495A-93FC-0C247A3E6E5F - 1 'Foo'])")
  }

  func testLegacyPresetKind() {
    let base64 = "WzAseyJuYW1lIjoiQ2xhdmluZXQiLCJzb3VuZEZvbnRLZXkiOiI4NDFDN0FBQS1DQTg3LTRCNkUtQTI2Ny1FQUQzNzMwMDkwNEYiLCJwYXRjaEluZGV4Ijo3fV0="
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNotNil(value)
    XCTAssertEqual(7, value?.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value?.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Clavinet", value?.soundFontAndPreset?.name)
  }
  
  func testFavoriteKind() {
    let preset = Preset("foo", 1, 2, 3)
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
                                                presetIndex: 1, name: "Foo")
    let favorite = Favorite(soundFontAndPreset: soundFontAndPreset,
                            presetConfig: preset.presetConfig,
                            keyboardLowestNote: Note(midiNoteValue: 64))

    let kind = ActivePresetKind.favorite(favorite: favorite)
    XCTAssertEqual(kind.soundFontAndPreset, soundFontAndPreset)
    XCTAssertEqual(kind.favorite, favorite)

    let dictData = kind.encodeToDict()
    XCTAssertNotNil(dictData)
    XCTAssertEqual(ActivePresetKind.decodeFromDict(dictData!), kind)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    XCTAssertNoThrow(try encoder.encode(kind))

    let json = try? encoder.encode(kind)
    XCTAssertNotNil(json)

    let decoder = JSONDecoder()
    XCTAssertNoThrow(try decoder.decode(ActivePresetKind.self, from: json!))
    let kinder = try? decoder.decode(ActivePresetKind.self, from: json!)
    XCTAssertNotNil(kinder)
    XCTAssertEqual(kind, kinder)

    XCTAssertEqual(kind.description, ".favorite('foo': [E621E1F8-C36C-495A-93FC-0C247A3E6E5F - 1 'Foo'])")
  }
}
