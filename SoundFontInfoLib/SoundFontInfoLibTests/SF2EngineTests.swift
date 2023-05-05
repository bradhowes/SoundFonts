// Copyright © 2022 Brad Howes. All rights reserved.

import Accelerate
import os.log
import XCTest
import SoundFontInfoLib
import SF2Files
import CoreAudio

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

  // swiftlint:disable function_body_length
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
    synth.engine.selectPreset(125)
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
    synth.engine.selectPreset(125)
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
// swiftlint:enable function_body_length

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

// These extension pertain to common AUv3 use-cases where we have one or more buffers of non-interleaved AUValue
// samples.
public extension AVAudioPCMBuffer {

  /**
   Obtain an UnsafeMutableBufferPointer for the given channel in the buffer

   - parameter index: the channel to return
   - returns: the UnsafeMutableBufferPointer for the channel data
   */
  subscript(index: Int) -> UnsafeMutableBufferPointer<AUValue> {
    UnsafeMutableBufferPointer<AUValue>(UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)[index])
  }

  /// - returns pointer to array of AUValue values representing the left channel of a stereo buffer pair.
  var leftPtr: UnsafeMutableBufferPointer<AUValue> { self[0] }

  /// - returns pointer to array of AUValue values representing the right channel of a stereo buffer pair.
  var rightPtr: UnsafeMutableBufferPointer<AUValue> { self[1] }

  /**
   Clear the buffer so that all `frameLength` samples are 0.0.
   */
  func zeros() {
    for index in 0..<Int(format.channelCount) {
      vDSP_vclr(self[index].baseAddress!, 1, vDSP_Length(frameLength))
    }
  }

  /**
   Append given buffer contents to the end of our contents

   - parameter buffer: the buffer to append
   */
  func append(_ buffer: AVAudioPCMBuffer) { append(buffer, startingFrame: 0, frameCount: buffer.frameLength) }

  /**
   Append given buffer contents to the end of our contents. Halts program if the buffer formats are not the same,
   the range of the source is invalid, or there is not enough space to hold the appended samples.

   - parameter buffer: the buffer to append
   - parameter startingFrame: the index of the first frame to append
   - parameter frameCount: the number of frames to append
   */
  func append(_ buffer: AVAudioPCMBuffer, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
    precondition(format == buffer.format)
    precondition(startingFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength))
    precondition(frameLength + frameCount <= frameCapacity)

    for index in 0..<Int(format.channelCount) {
      memcpy(self[index].baseAddress!.advanced(by: Int(frameLength)), buffer[index].baseAddress,
             Int(frameCount) * stride * MemoryLayout<Float>.size)
    }

    frameLength += frameCount
  }
}
