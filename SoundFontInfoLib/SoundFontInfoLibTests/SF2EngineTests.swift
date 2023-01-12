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

class SF2EngineTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var playFinishedExpectation: XCTestExpectation?

  func testCreating() {
    let engine = SF2Engine(voiceCount: 32)
    XCTAssertEqual(32, engine.voiceCount)
    XCTAssertEqual(0, engine.activeVoiceCount)
  }

  func testLoadingUrls() {
    let engine = SF2Engine(voiceCount: 32)
    engine.load(urls[0])
    XCTAssertEqual(189, engine.presetCount)

    engine.load(urls[1])
    XCTAssertEqual(235, engine.presetCount)

    engine.load(urls[2])
    XCTAssertEqual(270, engine.presetCount)

    engine.load(urls[3])
    XCTAssertEqual(1, engine.presetCount)
  }

  func testLoadingAllPresets() {
    let engine = SF2Engine(voiceCount: 32)
    engine.load(urls[2])
    XCTAssertEqual(270, engine.presetCount)
    for preset in 1..<engine.presetCount {
      engine.selectPreset(preset)
    }
  }

  func testLoadingTimes() {
    measure {
      let engine = SF2Engine(voiceCount: 32)
      engine.load(urls[2])
    }
  }

  func testNoteOn() {
    let engine = SF2Engine(voiceCount: 32)
    engine.load(urls[2])
    engine.selectPreset(0)
    engine.startNote(69, velocity: 64)
    XCTAssertEqual(1, engine.activeVoiceCount)
    engine.startNote(69, velocity: 64)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.stopNote(69, velocity: 0)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.stopAllNotes()
    XCTAssertEqual(0, engine.activeVoiceCount)
  }

  func testRenderProc() throws {
    let type = FourCharCode("aumu")
    let subType = FourCharCode("sfnt")
    let manufacturer = FourCharCode("BRay")
    let acd = AudioComponentDescription(componentType: type, componentSubType: subType,
                                        componentManufacturer: manufacturer, componentFlags: 0, componentFlagsMask: 0)

    let sampleRate = 48000.0
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 2, interleaved: false)!
    let maxFrameCount = AUAudioFrameCount(512)

    let synth = try SF2EngineAU.init(componentDescription: acd, options: [])
    synth.engine.load(urls[0])
    synth.engine.selectPreset(0)
    try synth.allocateRenderResources()
    let renderProc = synth.internalRenderBlock

    var flags = AudioUnitRenderActionFlags(rawValue: 0)
    var timestamp = AudioTimeStamp()

    let dryBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrameCount)!
    let reverbSendBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrameCount)!

    synth.engine.startNote(60, velocity: 64)
    synth.engine.startNote(64, velocity: 64)
    synth.engine.startNote(67, velocity: 64)

    let dryBufferList = dryBuffer.mutableAudioBufferList
    var buffers = UnsafeMutableAudioBufferListPointer(dryBufferList)
    var leftBuffer = buffers[0]
    var leftPtr = UnsafeMutableBufferPointer<AUValue>(leftBuffer)
    var rightBuffer = buffers[1]
    var rightPtr = UnsafeMutableBufferPointer<AUValue>(rightBuffer)
    vDSP_vclr(leftPtr.baseAddress!, 1, vDSP_Length(maxFrameCount))
    vDSP_vclr(rightPtr.baseAddress!, 1, vDSP_Length(maxFrameCount))

    var status = renderProc(&flags, &timestamp, maxFrameCount, 0, dryBufferList, nil, nil)
    XCTAssertEqual(status, 0)

    XCTAssertEqual(2, buffers.count)
    var left = buffers[0]
    XCTAssertEqual(2048, AUAudioFrameCount(left.mDataByteSize))
    var samples = UnsafeMutableBufferPointer<AUValue>(left)
    XCTAssertEqual(0.0, samples.first)
    XCTAssertEqual(-0.016753584, samples.last)
    var right = buffers[1]
    XCTAssertEqual(2048, AUAudioFrameCount(right.mDataByteSize))
    samples = UnsafeMutableBufferPointer<AUValue>(right)
    XCTAssertEqual(0.0, samples.first)
    XCTAssertEqual(0.04329596, samples.last)

    status = renderProc(&flags, &timestamp, maxFrameCount, 1, dryBufferList, nil, nil)
    XCTAssertEqual(status, 0)
    XCTAssertEqual(2, buffers.count)
    left = buffers[0]
    XCTAssertEqual(2048, AUAudioFrameCount(left.mDataByteSize))
    samples = UnsafeMutableBufferPointer<AUValue>(left)
    XCTAssertEqual(-0.016129782, samples.first)
    XCTAssertEqual(0.11220041, samples.last)
    right = buffers[1]
    XCTAssertEqual(2048, AUAudioFrameCount(right.mDataByteSize))
    samples = UnsafeMutableBufferPointer<AUValue>(right)
    XCTAssertEqual(-0.0019930205, samples.first)
    XCTAssertEqual(0.03206016, samples.last)

    let reverbSendBufferList = reverbSendBuffer.mutableAudioBufferList
    buffers = UnsafeMutableAudioBufferListPointer(reverbSendBufferList)
    leftBuffer = buffers[0]
    leftPtr = UnsafeMutableBufferPointer<AUValue>(leftBuffer)
    rightBuffer = buffers[1]
    rightPtr = UnsafeMutableBufferPointer<AUValue>(rightBuffer)
    vDSP_vclr(leftPtr.baseAddress!, 1, vDSP_Length(maxFrameCount))
    vDSP_vclr(rightPtr.baseAddress!, 1, vDSP_Length(maxFrameCount))

    status = renderProc(&flags, &timestamp, maxFrameCount, 2, reverbSendBufferList, nil, nil)
    XCTAssertEqual(status, 0)
    buffers = UnsafeMutableAudioBufferListPointer(reverbSendBufferList)
    XCTAssertEqual(2, buffers.count)
    left = buffers[0]
    XCTAssertEqual(2048, AUAudioFrameCount(left.mDataByteSize))
    samples = UnsafeMutableBufferPointer<AUValue>(left)
    XCTAssertEqual(0.092863545, samples.first)
    XCTAssertEqual(-0.10127042, samples.last)
    right = buffers[1]
    XCTAssertEqual(2048, AUAudioFrameCount(right.mDataByteSize))
    samples = UnsafeMutableBufferPointer<AUValue>(left)
    XCTAssertEqual(0.092863545, samples.first)
    XCTAssertEqual(-0.10127042, samples.last)
  }

  func testRenderPlayback() throws {
    let type = FourCharCode("aumu")
    let subType = FourCharCode("sfnt")
    let manufacturer = FourCharCode("BRay")
    let acd = AudioComponentDescription(componentType: type, componentSubType: subType,
                                        componentManufacturer: manufacturer, componentFlags: 0, componentFlagsMask: 0)

    let sampleRate = 44100.0
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 2, interleaved: false)!
    let frameCount = AUAudioFrameCount(512)

    let synth = try SF2EngineAU.init(componentDescription: acd, options: [])
    synth.engine.load(urls[0])
    synth.engine.selectPreset(0)
    try synth.allocateRenderResources()
    let renderProc = synth.internalRenderBlock

    var flags = AudioUnitRenderActionFlags(rawValue: 0)
    var timestamp = AudioTimeStamp()

    let seconds = 8
    let sampleCount = AUAudioFrameCount(seconds * Int(sampleRate))
    let playBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: sampleCount)!
    playBuffer.frameLength = 0

    let frames = sampleCount / frameCount
    let remaining = sampleCount - frames * frameCount
    let noteOnDuration = 50

    let dryBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
    let dryBufferList = dryBuffer.mutableAudioBufferList

    var frameIndex = 0
    let renderUntil = { (until: Int) in
      while frameIndex < until {
        frameIndex += 1
        dryBuffer.zeros()
        let status = renderProc(&flags, &timestamp, frameCount, 0, dryBufferList, nil, nil)
        if status == 0 {
          dryBuffer.frameLength = frameCount
          playBuffer.append(dryBuffer)
        }
      }
    }

    var noteOnFrame = 4
    var noteOffFrame = noteOnFrame + noteOnDuration

    let playChord = { (note1: UInt8, note2: UInt8, note3: UInt8, sustain: Bool) in
      renderUntil(noteOnFrame)
      synth.engine.startNote(note1, velocity: 64)
      synth.engine.startNote(note2, velocity: 64)
      synth.engine.startNote(note3, velocity: 64)
      renderUntil(noteOffFrame)
      if !sustain {
        synth.engine.stopNote(note1, velocity: 0)
        synth.engine.stopNote(note2, velocity: 0)
        synth.engine.stopNote(note3, velocity: 0)
      }
      noteOnFrame += noteOnDuration
      noteOffFrame += noteOnDuration
    }

    playChord(60, 64, 67, false)
    playChord(60, 65, 69, false)
    playChord(60, 64, 67, false)
    playChord(59, 62, 67, false)
    playChord(60, 64, 67, true)

    renderUntil(Int(frames))

    if remaining > 0 {
      dryBuffer.zeros()
      let status = renderProc(&flags, &timestamp, remaining, 0, dryBufferList, nil, nil)
      if status == 0 {
        dryBuffer.frameLength = remaining
        playBuffer.append(dryBuffer)
      }
    }

    playSamples(buffer: playBuffer, count: sampleCount)
  }
}

extension SF2EngineTests: AVAudioPlayerDelegate {

  func playSamples(buffer: AVAudioPCMBuffer, count: AVAudioFrameCount) {
    let uuid = UUID()
    let uuidString = uuid.uuidString
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let audioFileURL = temporaryDirectory.appendingPathComponent(uuidString).appendingPathExtension("caf")

    buffer.frameLength = count
    do {
      let audioFile = try AVAudioFile(forWriting: audioFileURL,
                                      settings: buffer.format.settings,
                                      commonFormat: .pcmFormatFloat32,
                                      interleaved: false)
      try audioFile.write(from: buffer)
    } catch {
      print("** failed to save AVAudioFile")
      return
    }

    do {
      let player = try AVAudioPlayer(contentsOf: audioFileURL)
      player.delegate = self
      playFinishedExpectation = self.expectation(description: "AVAudioPlayer finished")
      player.play()
      wait(for: [playFinishedExpectation!], timeout: 30.0)
    } catch {
      print("** failed to create AVAudioPlayer")
      return
    }
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    playFinishedExpectation!.fulfill()
  }
}
