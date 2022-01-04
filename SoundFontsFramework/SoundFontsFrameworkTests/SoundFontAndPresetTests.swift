// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class SoundFontAndPresetTests: XCTestCase {

  func testFoo() {
    let encoder = JSONEncoder()
    let value = SoundFontAndPreset(soundFontKey: UUID(), soundFontName: "soundFont", presetIndex: 123, itemName: "preset")
    let data = try! encoder.encode(value)
    let json = String(data: data, encoding: .utf8)!
    print(json)
  }

  func testMinV1Decoding() {
    let json = """
{"soundFontKey":"BA9469EA-FEC2-4F41-B4AA-4364B9101C09","patchIndex":123}
"""
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let value = try! decoder.decode(SoundFontAndPreset.self, from: data)
    XCTAssertNotNil(value)
    XCTAssertEqual(value.soundFontKey.uuidString, "BA9469EA-FEC2-4F41-B4AA-4364B9101C09")
    XCTAssertEqual(value.presetIndex, 123)
    XCTAssertEqual(value.itemName, "???")
  }

  func testV1Decoding() {
    let json = """
{"soundFontKey":"BA9469EA-FEC2-4F41-B4AA-4364B9101C09","patchIndex":123,"name":"hugo"}
"""
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let value = try! decoder.decode(SoundFontAndPreset.self, from: data)
    XCTAssertNotNil(value)
    XCTAssertEqual(value.soundFontKey.uuidString, "BA9469EA-FEC2-4F41-B4AA-4364B9101C09")
    XCTAssertEqual(value.presetIndex, 123)
    XCTAssertEqual(value.itemName, "hugo")
  }

  func testV2Decoding() {
    let json = """
{"soundFontKey":"BA9469EA-FEC2-4F41-B4AA-4364B9101C09","presetIndex":123,"itemName":"hugo","soundFontName":"Chavez"}
"""
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let value = try! decoder.decode(SoundFontAndPreset.self, from: data)
    XCTAssertNotNil(value)
    XCTAssertEqual(value.soundFontKey.uuidString, "BA9469EA-FEC2-4F41-B4AA-4364B9101C09")
    XCTAssertEqual(value.presetIndex, 123)
    XCTAssertEqual(value.itemName, "hugo")
  }

  func testInvalidPayload() {
    let json = """
{"oundFontKey":"BA9469EA-FEC2-4F41-B4AA-4364B9101C09","patchIndex":123}
"""
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let value = try? decoder.decode(SoundFontAndPreset.self, from: data)
    XCTAssertNil(value)
  }
}
