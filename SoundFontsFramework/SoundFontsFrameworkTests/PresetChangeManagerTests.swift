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

  func testLoading() async throws {
    loadFinishedExpectation = expectation(description: "load success")
    loadFinishedExpectation.expectedFulfillmentCount = 100
    loadFinishedExpectation?.assertForOverFulfill = true

    for index in 0..<100 {
      try await Task.sleep(nanoseconds: UInt64(0.01 * Double(NSEC_PER_SEC)))
      presetChangeManager.change(synth: synth, url: urls[0], preset: Preset("", 0, 0, index)) { result in
        if case .success = result {
          DispatchQueue.main.async { self.good += 1 }
        }
        self.loadFinishedExpectation?.fulfill()
      }
    }

    await fulfillment(of: [loadFinishedExpectation], timeout: 10.0)
    XCTAssertTrue(good > 1)
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
