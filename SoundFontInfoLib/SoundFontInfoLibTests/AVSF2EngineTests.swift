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

  func testCreating() {
    AUAudioUnit.registerSubclass(SF2EngineAU.self, as: AVSF2Engine.audioComponentDescription, name: "SF2Engine",
                                 version: 1)
    let exp = expectation(description: "instantiate")

    AVAudioUnit.instantiate(with: AVSF2Engine.audioComponentDescription) { avAudioUnit, err in
      XCTAssertNotNil(avAudioUnit)
      XCTAssertNil(err)
      let au = avAudioUnit?.auAudioUnit as? SF2EngineAU
      XCTAssertNotNil(au)
      exp.fulfill()
    }

    waitForExpectations(timeout: 10.0)
  }

  func testNotePlaying() {
    AUAudioUnit.registerSubclass(SF2EngineAU.self, as: AVSF2Engine.audioComponentDescription, name: "SF2Engine",
                                 version: 1)
    let exp = expectation(description: "instantiate")

    AVAudioUnit.instantiate(with: AVSF2Engine.audioComponentDescription) { avAudioUnit, err in
      guard let avAudioUnit = avAudioUnit as? AVAudioUnitMIDIInstrument else { XCTFail("nil avAudioUnit"); return }
      if let err = err { XCTFail("error - \(err)"); return }
      guard let au = avAudioUnit.auAudioUnit as? SF2EngineAU else { XCTFail("nil auAudioUnit"); return }

      let sampleRate = 44100.0
      let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 2, interleaved: false)!

      au.maximumFramesToRender = 512
      au.load(self.urls[0])
      // au.selectPreset(0)

      let engine = AVAudioEngine()
      engine.attach(avAudioUnit)
      engine.connect(avAudioUnit, to: engine.mainMixerNode, fromBus: 0, toBus: engine.mainMixerNode.nextAvailableInputBus, format: format)
      engine.prepare()

      do {
        try engine.start()
      } catch {
        XCTFail("failed to start")
      }

      au.noteOn(60, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      au.noteOn(64, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      au.noteOn(67, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      Thread.sleep(forTimeInterval: 1.0)
      au.noteOff(60)
      au.noteOff(64)
      au.noteOff(67)

      exp.fulfill()
    }

    waitForExpectations(timeout: 10.0)
  }
}
