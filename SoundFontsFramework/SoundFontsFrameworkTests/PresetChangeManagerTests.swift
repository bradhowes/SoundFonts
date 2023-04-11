// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework

import XCTest
import SoundFontInfoLib
import SF2Files
import AVFAudio

class PresetChangeManagerTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var loadFinishedExpectation: XCTestExpectation!

  var presetChangeManager: PresetChangeManager!
  var synth: SF2Engine! = nil
  var good = 0

  override func setUp() {
    synth = SF2Engine(voiceCount: 32)
    presetChangeManager = PresetChangeManager()
  }

  override func tearDownWithError() throws {
  }

  func testLoading() throws {
    loadFinishedExpectation = expectation(description: "load success")
    loadFinishedExpectation.expectedFulfillmentCount = 100
    loadFinishedExpectation?.assertForOverFulfill = true

    for index in 0..<100 {
      let preset = Preset("", 0, 0, index)
      DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .milliseconds(20 * index)) {
        self.presetChangeManager.change(synth: self.synth, url: self.urls[0], preset: preset) { result in
          if case .success = result {
            DispatchQueue.main.async { self.good += 1 }
          }
          self.loadFinishedExpectation?.fulfill()
        }
      }
    }

    wait(for: [loadFinishedExpectation], timeout: 10.0)
    print("----> good", good)
    XCTAssertTrue(good > 5)
  }

  func testFailures() throws {
    loadFinishedExpectation = expectation(description: "load failure")
    presetChangeManager.change(synth: synth, url: urls[3], preset: Preset("", 0, 0, 1)) { result in
      switch result {
      case .failure: self.loadFinishedExpectation?.fulfill()
      case .success: XCTFail("unexpected failure")
      }
    }
    waitForExpectations(timeout: 10.0)
  }
}
