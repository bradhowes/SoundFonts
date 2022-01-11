// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

private let suiteName = "ActivePresetKindTests"

class ActivePresetKindTests: XCTestCase {

  func _testEncodings() {
    let kind = ActivePresetKind.none
    let encoder = JSONEncoder()
    XCTAssertNoThrow(try encoder.encode(kind))
    let json = try! encoder.encode(kind)
    print(String(data: json, encoding: .utf8)!)
  }

  func testPresetKind() {
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
                                                soundFontName: "Booboo", presetIndex: 1, itemName: "Foo")
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

    XCTAssertEqual(kind.description, ".preset(<E621E1F8-C36C-495A-93FC-0C247A3E6E5F[1]: 'Foo'>)")
  }

  func testFavoriteKind() {
    let preset = Preset("foo", 1, 2, 3)
    let soundFontAndPreset = SoundFontAndPreset(soundFontKey: SoundFont.Key(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
                                                soundFontName: "Hubba", presetIndex: 1, itemName: "Foo")
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
    // encoder.outputFormatting = .prettyPrinted
    XCTAssertNoThrow(try encoder.encode(kind))

    let json = try? encoder.encode(kind)
    XCTAssertNotNil(json)
    print(String(data: json!, encoding: .utf8)!)

    let decoder = JSONDecoder()
    XCTAssertNoThrow(try decoder.decode(ActivePresetKind.self, from: json!))
    let kinder = try? decoder.decode(ActivePresetKind.self, from: json!)
    XCTAssertNotNil(kinder)
    XCTAssertEqual(kind, kinder)

    XCTAssertEqual(kind.description, ".favorite('foo': <E621E1F8-C36C-495A-93FC-0C247A3E6E5F[1]: 'Foo'>)")
  }

  func testNoneKind() {
    let kind = ActivePresetKind.none
    XCTAssertNil(kind.soundFontAndPreset)
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

    XCTAssertEqual(kind.description, ".none")
  }

  func testBogusEncoding1() {
    let json = "[0,{\"name\":\"Clavinet\",\"oundFontKey\":\"841C7AAA-CA87-4B6E-A267-EAD37300904F\",\"patchIndex\":7}]"

    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNil(value)
  }

  func testBogusEncodingInvalidKey() {
    let json = """
    {"value":{"itemName":"Foo","soundFontKey":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","presetIndex":1,"soundFontName":"Booboo"},"internalKey":99}
"""
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNil(value)
  }

  func testBogusEncodingInvalidPayload() {
    let json = """
    {"value":{"itemName":"Foo","soundFontKey":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","presetIndex":1,"soundFontName":"Booboo"},"internalKey":1}
"""
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNil(value)
  }

  func testBogusLegacyKind() {
    let json = """
    []
    """
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNil(value)
  }

  func testInvalidLegacyKind() {
    let json = """
    [-1]
    """
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNil(value)
  }

  func testLegacyNoneKind() {
    let json = """
    [2]
    """
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertEqual(value!, .none)
  }

  func testLegacyPresetKind() {
    let base64 = "WzAseyJuYW1lIjoiQ2xhdmluZXQiLCJzb3VuZEZvbnRLZXkiOiI4NDFDN0FBQS1DQTg3LTRCNkUtQTI2Ny1FQUQzNzMwMDkwNEYiLCJwYXRjaEluZGV4Ijo3fV0="
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNotNil(value)
    XCTAssertEqual(7, value?.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value?.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Clavinet", value?.soundFontAndPreset?.itemName)
  }

  func testLegacyFavoriteKind() {
    let json = """
[1,{"key":"9CB443ED-8C29-4233-BC78-0016E502CAF2","soundFontAndPatch":{"itemName":"Foo","soundFontKey":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","presetIndex":1,"soundFontName":"Hubba"},"presetConfig":{"keyboardLowestNoteEnabled":false,"pan":0,"keyboardLowestNote":{"midiNoteValue":64,"accented":false},"presetTuning":0,"presetTuningEnabled":false,"gain":0,"name":"foo"}}]
"""
    let base64 = Data(json.utf8).base64EncodedString()
    let data = Data(base64Encoded: base64)
    XCTAssertNotNil(data)
    let value = ActivePresetKind.decodeFromData(data!)
    XCTAssertNotNil(value)
    XCTAssertEqual(1, value?.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("E621E1F8-C36C-495A-93FC-0C247A3E6E5F", value?.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Foo", value?.soundFontAndPreset?.itemName)
  }

  func testRegister() {
    let foo = "register_foo"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removeObject(forKey: foo)
    ActivePresetKind.register(key: foo, value: .none, source: userDefaults)
    let obj = userDefaults.object(forKey: foo)
    XCTAssertNotNil(obj)
    let dict = obj as? [String: Int]
    XCTAssertEqual(dict, ["internalKey": 2])
  }

  func testSettingsGet() {
    let foo = "get_foo"
    let bar = "get_bar"
    let settings = Settings(suiteName: suiteName)
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removeObject(forKey: foo)
    userDefaults.removeObject(forKey: bar)

    // No previous setting
    var kind = ActivePresetKind.get(key: foo, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)
    XCTAssertNotNil(userDefaults.object(forKey: foo))

    // Legacy previous setting
    userDefaults.set(Data(base64Encoded: Data("[2]".utf8).base64EncodedString())!, forKey: bar)
    kind = ActivePresetKind.get(key: bar, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)

    // Invalid legacy previous setting
    userDefaults.set(Data(base64Encoded: Data("[999]".utf8).base64EncodedString())!, forKey: bar)
    kind = ActivePresetKind.get(key: bar, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)

    // Invalid dict value
    userDefaults.set(["Hello": "mom"], forKey: bar)
    kind = ActivePresetKind.get(key: bar, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)

    // Invalid data type
    userDefaults.set(15, forKey: foo)
    kind = ActivePresetKind.get(key: foo, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)

    // Fetch after setting
    kind = ActivePresetKind.get(key: foo, defaultValue: .none, source: settings)
    XCTAssertEqual(kind, .none)
  }

  func testSettingsSet() {
    let foo = "set_foo"
    let settings = Settings(suiteName: suiteName)
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removeObject(forKey: foo)
    ActivePresetKind.set(key: foo, value: .none, source: settings)
    XCTAssertNotNil(userDefaults.object(forKey: foo))
  }
}
