// Copyright © 2022 Brad Howes. All rights reserved.

import Accelerate
import os.log
import XCTest
import SoundFontInfoLib
import SF2Files
import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import GameKit
import AUv3Support

class AVSF2EngineTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var playFinishedExpectation: XCTestExpectation?

  func testCreating() {
    let engine = AVSF2Engine()
    XCTAssertNotNil(engine)
  }
}
