// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import SF2Files

class FileTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }

  func testParsing1() {
    let sfi = SoundFontInfo.load(viaFile: urls[0])!

    XCTAssertEqual(sfi.embeddedName, "Fluid R3 GM")
    XCTAssertEqual(sfi.presets.count, 189)

    XCTAssertEqual(sfi.presets[0].name, "Yamaha Grand Piano")
    XCTAssertEqual(sfi.presets[0].bank, 0)
    XCTAssertEqual(sfi.presets[0].preset, 0)

    let lastPatchIndex = sfi.presets.count - 1
    XCTAssertEqual(sfi.presets[lastPatchIndex].name, "Orchestra Kit")
    XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 48)
  }

  func testParsing2() {
    let sfi = SoundFontInfo.load(viaFile: urls[1])!

    XCTAssertEqual(sfi.embeddedName, "Free Font GM Ver. 3.2")
    XCTAssertEqual(sfi.presets.count, 235)

    XCTAssertEqual(sfi.presets[0].name, "Piano 1")
    XCTAssertEqual(sfi.presets[0].bank, 0)
    XCTAssertEqual(sfi.presets[0].preset, 0)

    let lastPatchIndex = sfi.presets.count - 1
    XCTAssertEqual(sfi.presets[lastPatchIndex].name, "SFX")
    XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 56)
  }

  func testParsing3() {
    let sfi = SoundFontInfo.load(viaFile: urls[2])!

    XCTAssertEqual(sfi.embeddedName, "GeneralUser GS MuseScore version 1.442")
    XCTAssertEqual(sfi.presets.count, 270)

    XCTAssertEqual(sfi.presets[0].name, "Stereo Grand")
    XCTAssertEqual(sfi.presets[0].bank, 0)
    XCTAssertEqual(sfi.presets[0].preset, 0)

    let lastPatchIndex = sfi.presets.count - 1
    XCTAssertEqual(sfi.presets[lastPatchIndex].name, "SFX")
    XCTAssertEqual(sfi.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(sfi.presets[lastPatchIndex].preset, 56)
  }

  func testParsing4() {
    let sfi = SoundFontInfo.load(viaFile: urls[3])!

    XCTAssertEqual(sfi.embeddedName, "User Bank")
    XCTAssertEqual(sfi.presets.count, 1)

    XCTAssertEqual(sfi.presets[0].name, "Nice Piano")
    XCTAssertEqual(sfi.presets[0].bank, 0)
    XCTAssertEqual(sfi.presets[0].preset, 1)
  }
}
