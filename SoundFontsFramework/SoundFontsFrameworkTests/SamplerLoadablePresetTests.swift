// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework

import XCTest
import SF2Files
import AVFAudio

class SamplerLoadablePresetTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var loadFinishedExpectation: XCTestExpectation?

  var engine: AVAudioEngine! = nil
  var synth: AVAudioUnitSampler! = nil

  override func setUp() {
    engine = AVAudioEngine()
    synth = AVAudioUnitSampler()
    engine.attach(synth)
    engine.connect(synth, to: engine.mainMixerNode, format: nil)
    engine.prepare()
    XCTAssertNoThrow(try engine.start())
  }

  override func tearDownWithError() throws {
    engine.stop()
    engine.disconnectNodeOutput(synth)
    engine.detach(synth)
  }

  func testLoading() throws {
    let error = synth.loadAndActivatePreset(Preset("", 0, 0, 0), from: urls[0])
    XCTAssertNil(error)
  }

  func testBadUrl() throws {
    let error = synth.loadAndActivatePreset(Preset("", 0, 0, 0), from: urls[0].appendingPathExtension("blah"))
    XCTAssertNotNil(error)
    XCTAssertEqual(error?.code, -43)

  }

  func testBadPreset() throws {
    let error = synth.loadAndActivatePreset(Preset("", 127, 127, 0), from: urls[0])
    XCTAssertNotNil(error)
    XCTAssertEqual(error?.code, -10851)
  }
}
