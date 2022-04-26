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

    let uuid = UUID()
    let uuidString = uuid.uuidString
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let audioFileURL = temporaryDirectory.appendingPathComponent(uuidString).appendingPathExtension("caf")

    AVAudioUnit.instantiate(with: AVSF2Engine.audioComponentDescription) { avAudioUnit, err in
      guard let avAudioUnit = avAudioUnit as? AVAudioUnitMIDIInstrument else { XCTFail("nil avAudioUnit"); return }
      if let err = err { XCTFail("error - \(err)"); return }
      guard let au = avAudioUnit.auAudioUnit as? SF2EngineAU else { XCTFail("nil auAudioUnit"); return }

      au.maximumFramesToRender = 512
      au.load(self.urls[0])
      // au.selectPreset(0)

      let engine = AVAudioEngine()
      engine.attach(avAudioUnit)
      engine.connect(avAudioUnit, to: engine.mainMixerNode, fromBus: 0,
                     toBus: engine.mainMixerNode.nextAvailableInputBus, format: nil)
      engine.prepare()

      // TODO: don't connect to speaker and evaluate recording for proper samples.
      do {
        try engine.start()
      } catch {
        XCTFail("failed to start engine")
        return
      }

      let audioFile: AVAudioFile

      do {
        audioFile = try AVAudioFile(forWriting: audioFileURL,
                                    settings: engine.mainMixerNode.inputFormat(forBus: 0).settings,
                                    commonFormat: .pcmFormatFloat32, interleaved: false)
      } catch {
        XCTFail("failed to create AVAudioFile")
        return
      }

      engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024,
                                      format: engine.mainMixerNode.inputFormat(forBus: 0)) { buffer, _ in
        try? audioFile.write(from: buffer)
      }

      au.startNote(note: 60, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      au.startNote(note: 64, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      au.startNote(note: 67, velocity: 64) // avAudioUnit.startNote(64, withVelocity: 127, onChannel: 0)
      Thread.sleep(forTimeInterval: 4.0)
      au.stopNote(note: 60, velocity: 0)
      au.stopNote(note: 64, velocity: 0)
      au.stopNote(note: 67, velocity: 0)

      engine.mainMixerNode.removeTap(onBus: 0)
      exp.fulfill()
    }

    wait(for: [exp], timeout: 10.0)

    // Play the samples from the tap
//    do {
//      let player = try AVAudioPlayer(contentsOf: audioFileURL)
//      player.delegate = self
//      playFinishedExpectation = self.expectation(description: "AVAudioPlayer finished")
//      player.play()
//      wait(for: [playFinishedExpectation!], timeout: 30.0)
//    } catch {
//      print("** failed to create AVAudioPlayer")
//      return
//    }
  }
}

extension AVSF2EngineTests: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    playFinishedExpectation!.fulfill()
  }
}
