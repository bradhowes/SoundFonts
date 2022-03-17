// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import SF2Files

class SF2EngineTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }
  var playFinishedExpectation: XCTestExpectation?

  func testCreating() {
    let engine = SF2Engine(32)
    XCTAssertEqual(32, engine.voiceCount)
    XCTAssertEqual(0, engine.activeVoiceCount)
  }

  func testLoadingUrls() {
    let engine = SF2Engine(32)
    engine.load(urls[0], preset: 0)
    XCTAssertEqual(189, engine.presetCount)

    engine.load(urls[1], preset: 0)
    XCTAssertEqual(235, engine.presetCount)

    engine.load(urls[2], preset: 0)
    XCTAssertEqual(270, engine.presetCount)

    engine.load(urls[3], preset: 0)
    XCTAssertEqual(1, engine.presetCount)
  }

  func testLoadingAllPresets() {
    let engine = SF2Engine(32)
    engine.load(urls[2], preset: 0)
    XCTAssertEqual(270, engine.presetCount)
    for preset in 1..<engine.presetCount {
      engine.load(urls[2], preset: preset)
    }
  }

  func testLoadingTimes() {
    measure {
      let engine = SF2Engine(32)
      engine.load(urls[2], preset: 0)
    }
  }

  func testNoteOn() {
    let engine = SF2Engine(32)
    engine.load(urls[2], preset: 0)
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(1, engine.activeVoiceCount)
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.noteOff(69)
    XCTAssertEqual(2, engine.activeVoiceCount)
    engine.allOff()
    XCTAssertEqual(0, engine.activeVoiceCount)
  }

  func testRendering() {
    let sampleRate: Double = 44100
    let frameCount: AVAudioFrameCount = 512
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
    let engine = SF2Engine(32)
    engine.load(urls[2], preset: 0)
    engine.setRenderingFormat(format, maxFramesToRender: frameCount)

    // Set NPRN state so that voices send 20% output to the chorus channel
//    engine.nprn().process(MIDI::ControlChange::nprnMSB, 120);
//    engine.nprn().process(MIDI::ControlChange::nprnLSB, int(Entity::Generator::Index::chorusEffectSend));
//    engine.channelState().setContinuousControllerValue(MIDI::ControlChange::dataEntryLSB, 72);
//    engine.nprn().process(MIDI::ControlChange::dataEntryMSB, 65);

    let seconds: AVAudioFrameCount = 6
    let sampleCount = AVAudioFrameCount(sampleRate) * seconds
    let frames = sampleCount / frameCount
    let remaining = sampleCount - frames * frameCount
    var noteOnFrame = 10
    let noteOnDuration = 50
    var noteOffFrame = noteOnFrame + noteOnDuration

    let dryBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))!
    var bufferList = dryBuffer.mutableAudioBufferList
    bufferList.pointee.mBuffers.mDataByteSize = sampleCount * 4
    bufferList.successor().pointee.mBuffers.mDataByteSize = sampleCount * 4

    // Utils::OutputBufferPair dry{(float*)(bufferList->mBuffers[0].mData), (float*)(bufferList->mBuffers[1].mData),
    // AUAudioFrameCount(sampleCount)};

    //  AVAudioPCMBuffer* chorusBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
    //  assert(chorusBuffer != nullptr);
    //
    //  bufferList = chorusBuffer.mutableAudioBufferList;
    //  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
    //  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);
    //
    //  Utils::OutputBufferPair chorusSend{(float*)(bufferList->mBuffers[0].mData), (float*)(bufferList->mBuffers[1].mData),
    //    AUAudioFrameCount(sampleCount)};
    //  Utils::OutputBufferPair reverbSend;
    //  Utils::Mixer mixer{dry, chorusSend, reverbSend};

    XCTAssertEqual(0, engine.activeVoiceCount)

//  int frameIndex = 0;
//  auto renderUntil = [&](int until) {
//    while (frameIndex++ < until) {
//      engine.renderInto(mixer, frameCount);
//    }
//  };
//
//  auto playChord = [&](int note1, int note2, int note3) {
//    renderUntil(noteOnFrame);
//    engine.noteOn(note1, 64);
//    engine.noteOn(note2, 64);
//    engine.noteOn(note3, 64);
//    renderUntil(noteOffFrame);
//    engine.noteOff(note1);
//    engine.noteOff(note2);
//    engine.noteOff(note3);
//    noteOnFrame += noteOnDuration;
//    noteOffFrame += noteOnDuration;
//  };
//
//  playChord(60, 64, 67);
//  playChord(60, 65, 69);
//  playChord(60, 64, 67);
//  playChord(59, 62, 67);
//  playChord(60, 64, 67);
//
//  renderUntil(frameCount);
//  if (remaining > 0) {
//    engine.renderInto(mixer, frameCount);
//  }
//
//  XCTAssertEqual(2, engine.activeVoiceCount());
//
//  [self playSamples: dryBuffer count: sampleCount];
//  [self playSamples: chorusBuffer count: sampleCount];
  }
}

extension SF2EngineTests: AVAudioPlayerDelegate {

  func playSamples(buffer: AVAudioPCMBuffer, count: AVAudioFrameCount) {
    let uuid = UUID()
    let uuidString = uuid.uuidString
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let audioFileURL = temporaryDirectory.appendingPathComponent(uuidString).appendingPathExtension(".caf")

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
