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

extension FourCharCode: ExpressibleByStringLiteral {

  public init(stringLiteral value: StringLiteralType) {
    var code: FourCharCode = 0
    // Value has to consist of 4 printable ASCII characters, e.g. '420v'.
    // Note: This implementation does not enforce printable range (32-126)
    if value.count == 4 && value.utf8.count == 4 {
      for byte in value.utf8 {
        code = code << 8 + FourCharCode(byte)
      }
    } else {
      os_log(
        .error,
        "FourCharCode: Can't initialize with '%s', only printable ASCII allowed. Setting to '????'.",
        value)
      code = 0x3F3F_3F3F  // = '????'
    }
    self = code
  }

  public init(extendedGraphemeClusterLiteral value: String) {
    self = FourCharCode(stringLiteral: value)
  }
  public init(unicodeScalarLiteral value: String) { self = FourCharCode(stringLiteral: value) }
  public init(_ value: String) { self = FourCharCode(stringLiteral: value) }
}

class SF2EngineTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var playFinishedExpectation: XCTestExpectation?

  func testCreating() {
    let engine = SF2Engine(loggingBase: "SF2Engine", voiceCount: 32)
    XCTAssertEqual(32, engine.voiceCount)
    XCTAssertEqual(0, engine.activeVoiceCount)
  }

  func testLoadingUrls() {
    let engine = SF2Engine(loggingBase: "SF2Engine", voiceCount: 32)
    engine.load(urls[0], preset: 0, shortName: "Piano")
    XCTAssertEqual(189, engine.presetCount)

    engine.load(urls[1], preset: 0, shortName: "Piano")
    XCTAssertEqual(235, engine.presetCount)

    engine.load(urls[2], preset: 0, shortName: "Piano")
    XCTAssertEqual(270, engine.presetCount)

    engine.load(urls[3], preset: 0, shortName: "Piano")
    XCTAssertEqual(1, engine.presetCount)
  }

  func testLoadingAllPresets() {
    let engine = SF2Engine(loggingBase: "SF2Engine", voiceCount: 32)
    engine.load(urls[2], preset: 0, shortName: "Piano")
    XCTAssertEqual(270, engine.presetCount)
    for preset in 1..<engine.presetCount {
      engine.load(urls[2], preset: preset, shortName: "Whatever")
    }
  }

  func testLoadingTimes() {
    measure {
      let engine = SF2Engine(loggingBase: "SF2Engine", voiceCount: 32)
      engine.load(urls[2], preset: 0, shortName: "Piano")
    }
  }

  func testNoteOn() {
    let engine = SF2Engine(loggingBase: "SF2Engine", voiceCount: 32)
    engine.load(urls[2], preset: 0, shortName: "Piano")
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(1, engine.activeVoiceCount)
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.noteOff(69)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.allOff()
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
    synth.engine.load(urls[0], preset: 0, shortName: "Piano")
    try synth.allocateRenderResources()
    let renderProc = synth.internalRenderBlock

    var flags = AudioUnitRenderActionFlags(rawValue: 0)
    var timestamp = AudioTimeStamp()

    let dryBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrameCount)!
    let chorusSendBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrameCount)!
    let reverbSendBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrameCount)!

    synth.engine.note(on: 60, velocity: 64)
    synth.engine.note(on: 64, velocity: 64)
    synth.engine.note(on: 67, velocity: 64)

    let dryBufferList = dryBuffer.mutableAudioBufferList
    var status = renderProc(&flags, &timestamp, maxFrameCount, 0, dryBufferList, nil, nil)
    XCTAssertEqual(status, 0)

    var buffers = UnsafeMutableAudioBufferListPointer(dryBufferList)
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

    let chorusSendBufferList = chorusSendBuffer.mutableAudioBufferList
    status = renderProc(&flags, &timestamp, maxFrameCount, 1, chorusSendBufferList, nil, nil)
    XCTAssertEqual(status, 0)
    buffers = UnsafeMutableAudioBufferListPointer(chorusSendBufferList)
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
    synth.engine.load(urls[0], preset: 0, shortName: "Piano")
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
    let buffers = UnsafeMutableAudioBufferListPointer(dryBufferList)
    let leftBuffer = buffers[0]
    let leftPtr = UnsafeMutableBufferPointer<AUValue>(leftBuffer)
    let rightBuffer = buffers[1]
    let rightPtr = UnsafeMutableBufferPointer<AUValue>(rightBuffer)

    var frameIndex = 0;
    let renderUntil = { (until: Int) in
      while frameIndex < until {
        frameIndex += 1
        vDSP_vclr(leftPtr.baseAddress!, 1, 512)
        vDSP_vclr(rightPtr.baseAddress!, 1, 512)
        let status = renderProc(&flags, &timestamp, frameCount, 0, dryBufferList, nil, nil)
        if status == 0 {
          dryBuffer.frameLength = frameCount
          playBuffer.append(dryBuffer)
        }
      }
    }

    var noteOnFrame = 4
    var noteOffFrame = noteOnFrame + noteOnDuration

    let playChord = { (note1: Int32, note2: Int32, note3: Int32, sustain: Bool) in
      renderUntil(noteOnFrame)
      synth.engine.note(on: note1, velocity: 64)
      synth.engine.note(on: note2, velocity: 64)
      synth.engine.note(on: note3, velocity: 64)
      renderUntil(noteOffFrame)
      if !sustain {
        synth.engine.noteOff(note1)
        synth.engine.noteOff(note2)
        synth.engine.noteOff(note3)
      }
      noteOnFrame += noteOnDuration;
      noteOffFrame += noteOnDuration;
    };

    playChord(60, 64, 67, false)
    playChord(60, 65, 69, false)
    playChord(60, 64, 67, false)
    playChord(59, 62, 67, false)
    playChord(60, 64, 67, true)

    renderUntil(Int(frames))

    if remaining > 0 {
      vDSP_vclr(leftPtr.baseAddress!, 1, 512)
      vDSP_vclr(rightPtr.baseAddress!, 1, 512)
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

extension AVAudioPCMBuffer {

  func append(_ buffer: AVAudioPCMBuffer) { append(buffer, startingFrame: 0, frameCount: buffer.frameLength) }

  func append(_ buffer: AVAudioPCMBuffer, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
    precondition(format == buffer.format, "Format mismatch")
    precondition(startingFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength),
                 "Insufficient audio in buffer")
    precondition(frameLength + frameCount <= frameCapacity, "Insufficient space in buffer")

    let src = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
    let srcLeft = src[0]
    let srcLeftPtr = UnsafeMutableBufferPointer<AUValue>(srcLeft)
    let srcRight = src[1]
    let srcRightPtr = UnsafeMutableBufferPointer<AUValue>(srcRight)

    let dest = UnsafeMutableAudioBufferListPointer(self.mutableAudioBufferList)
    let destLeft = dest[0]
    let destLeftPtr = UnsafeMutableBufferPointer<AUValue>(destLeft)
    let destRight = dest[1]
    let destRightPtr = UnsafeMutableBufferPointer<AUValue>(destRight)

    memcpy(destLeftPtr.baseAddress!.advanced(by: Int(frameLength)),
           srcLeftPtr.baseAddress,
           Int(frameCount) * stride * MemoryLayout<Float>.size)

    memcpy(destRightPtr.baseAddress!.advanced(by: Int(frameLength)),
           srcRightPtr.baseAddress,
           Int(frameCount) * stride * MemoryLayout<Float>.size)

    frameLength += frameCount
  }
}
