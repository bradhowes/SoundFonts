// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import SF2Files

class SoundFontInfoLibTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }

  func testParsing1() {
    let info = SoundFontInfo.load(viaParser: urls[0])!

    XCTAssertEqual(info.embeddedName, "Fluid R3 GM")
    XCTAssertEqual(info.presets.count, 189)
    XCTAssertEqual(info.presets[0].name, "Yamaha Grand Piano")
    XCTAssertEqual(info.presets[0].bank, 0)
    XCTAssertEqual(info.presets[0].preset, 0)

    let lastPatchIndex = info.presets.count - 1
    XCTAssertEqual(info.presets[lastPatchIndex].name, "Orchestra Kit")
    XCTAssertEqual(info.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(info.presets[lastPatchIndex].preset, 48)
  }

  func testParsing2() {
    let info = SoundFontInfo.load(viaParser: urls[1])!

    XCTAssertEqual(info.embeddedName, "Free Font GM Ver. 3.2")
    XCTAssertEqual(info.presets.count, 235)

    XCTAssertEqual(info.presets[0].name, "Piano 1")
    XCTAssertEqual(info.presets[0].bank, 0)
    XCTAssertEqual(info.presets[0].preset, 0)

    let lastPatchIndex = info.presets.count - 1
    XCTAssertEqual(info.presets[lastPatchIndex].name, "SFX")
    XCTAssertEqual(info.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(info.presets[lastPatchIndex].preset, 56)
  }

  func testParsing3() {
    let info = SoundFontInfo.load(viaParser: urls[2])!

    XCTAssertEqual(info.embeddedName, "GeneralUser GS MuseScore version 1.442")
    XCTAssertEqual(info.presets.count, 270)

    XCTAssertEqual(info.presets[0].name, "Stereo Grand")
    XCTAssertEqual(info.presets[0].bank, 0)
    XCTAssertEqual(info.presets[0].preset, 0)

    let lastPatchIndex = info.presets.count - 1
    XCTAssertEqual(info.presets[lastPatchIndex].name, "SFX")
    XCTAssertEqual(info.presets[lastPatchIndex].bank, 128)
    XCTAssertEqual(info.presets[lastPatchIndex].preset, 56)
  }

  func testParsing4() {
    let info = SoundFontInfo.load(viaParser: urls[3])!

    XCTAssertEqual(info.embeddedName, "User Bank")
    XCTAssertEqual(info.presets.count, 1)

    XCTAssertEqual(info.presets[0].name, "Nice Piano")
    XCTAssertEqual(info.presets[0].bank, 0)
    XCTAssertEqual(info.presets[0].preset, 1)
  }

  var newTempFileURL: URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
  }

  /**
   Generate file with random contents and try to process them to make sure that there are no BAD_ACCESS
   exceptions.
   */
  func testRobustnessWithRandomPayload() {
    let tmp = newTempFileURL
    defer { try? FileManager.default.removeItem(at: tmp) }

    let size = 2048
    var data = Data(count: size)
    _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
    do {
      try data.write(to: tmp, options: .atomic)
    } catch _ as NSError {
      fatalError()
    }
    let result = SoundFontInfo.load(viaParser: tmp)
    XCTAssertNil(result)
  }

  /**
   Generate partial soundfont file contents and try to process them to make sure that there are no BAD_ACCESS
   exceptions.
   */
  func testRobustnessWithPartialPayload() {
    let tmp = newTempFileURL
    defer { try? FileManager.default.removeItem(at: tmp) }

    guard let original = try? Data(contentsOf: urls[0]) else { fatalError() }
    for _ in 0..<20 {
      let truncatedCount = Int.random(in: 1..<(original.count / 2))
      let data = original.subdata(in: 0..<truncatedCount)
      do {
        try data.write(to: tmp, options: .atomic)
      } catch _ as NSError {
        fatalError()
      }
      let result = SoundFontInfo.load(viaParser: tmp)
      XCTAssertNil(result)
    }
  }
}
