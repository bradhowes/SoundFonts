// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework

import XCTest
import SoundFontInfoLib
import SF2Files
import AVFAudio

class SF2EngineLoadablePresetTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var loadFinishedExpectation: XCTestExpectation?

  var synth: SF2Engine! = nil

  override func setUp() {
    synth = SF2Engine(voiceCount: 32)
  }

  override func tearDownWithError() throws {
  }

  func testLoading() throws {
    let error = synth.loadAndActivatePreset(Preset("", 0, 0, 0), from: urls[0])
    XCTAssertNil(error)
  }

  func testBadUrl() throws {
    // NOTE: there is an internal race in the AVAudioEngine which can cause crashes if an instance is disposed soon
    // after loading a soundfont. Unfortunately, there is no call I know of yet to determine when the loading is
    // actually done.
    let error = synth.loadAndActivatePreset(Preset("", 0, 0, 0), from: urls[0].appendingPathExtension("blah"))
    XCTAssertNotNil(error)
    XCTAssertEqual(error?.code, 100)
  }

  func testBadPreset() throws {
    let error = synth.loadAndActivatePreset(Preset("", 127, 127, 9999), from: urls[0])
    XCTAssertNotNil(error)
    XCTAssertEqual(error?.code, 300)
  }
}
