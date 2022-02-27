// Copyright © 2020 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <iostream>

#import "Render/Preset.hpp"
#import "Render/Voice/Sample/Generator.hpp"
#import "Render/Voice/Voice.hpp"

#import "SampleBasedContexts.hpp"

using namespace SF2;
using namespace SF2::Render;

@interface VoiceTests : XCTestCase <AVAudioPlayerDelegate>
@property (nonatomic) bool playAudio;
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) XCTestExpectation* expectation;
@property (nonatomic, retain) NSURL* audioFileURL;
@end

@implementation VoiceTests {
  SampleBasedContexts contexts;
}

- (void)setUp {
#ifdef PLAY_AUDIO // See Development.xcconfig
  self.playAudio = YES;
#else
  self.playAudio = NO;
#endif
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
  [self.expectation fulfill];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
}

- (void)testRolandPianoRender {
  Float epsilon = 0.000001;
  const auto& file = contexts.context3.file();

  MIDI::Channel channel;
  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[0]);

  auto found = preset.find(69, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v1L{44100, channel, 0};
  v1L.configure(found[0]);
  Voice::Voice v1R{44100, channel, 1};
  v1R.configure(found[1]);

  found = preset.find(73, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v2L{44100, channel, 2};
  v2L.configure(found[0]);
  Voice::Voice v2R{44100, channel, 3};
  v2R.configure(found[1]);

  found = preset.find(76, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v3L{44100, channel, 4};
  v3L.configure(found[0]);
  Voice::Voice v3R{44100, channel, 5};
  v3R.configure(found[1]);

  Float sampleRate = 44100.0;
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

  int seconds = 1;
  int sampleCount = sampleRate * seconds;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
  AudioBufferList* bufferList = buffer.mutableAudioBufferList;
  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);
  float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
  float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

  size_t keyReleaseCount{size_t(sampleCount / 4)};
  size_t voiceSampleCount{size_t(sampleCount / 3)};
  std::vector<AUValue> samples;

  auto renderLR = [&](auto& left, auto& right, bool dump = false) {
    for (auto index = 0; index < voiceSampleCount; ++index) {
      AUValue sample = left.renderSample();
      if (dump) std::cout << sample << '\n';
      *samplesLeft++ = sample;
      *samplesRight++ = right.renderSample();
      if (index == 0 || index == voiceSampleCount - 1) {
        samples.push_back(sample);
      }
      else if (index == keyReleaseCount) {
        samples.push_back(sample);
        left.releaseKey();
        right.releaseKey();
      }
    }
  };

  renderLR(v1L, v1R);
  renderLR(v2L, v2R);
  renderLR(v3L, v3R);

  XCTAssertEqual(9, samples.size());
  XCTAssertEqualWithAccuracy( 0.000000, samples[0], epsilon);
  XCTAssertEqualWithAccuracy( 0.293332, samples[1], epsilon);
  XCTAssertEqualWithAccuracy(-0.259781, samples[2], epsilon);
  XCTAssertEqualWithAccuracy( 0.000000, samples[3], epsilon);
  XCTAssertEqualWithAccuracy( 0.128983, samples[4], epsilon);
  XCTAssertEqualWithAccuracy(-0.146351, samples[5], epsilon);
  XCTAssertEqualWithAccuracy( 0.000000, samples[6], epsilon);
  XCTAssertEqualWithAccuracy(-0.218109, samples[7], epsilon);
  XCTAssertEqualWithAccuracy(-0.063845, samples[8], epsilon);

  [self playSamples: buffer count: sampleCount];
}

- (void)testBrass2Render {
  double epsilon = 0.000001;
  const auto& file = contexts.context2.file();

  MIDI::Channel channel;
  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[19]);

  auto found = preset.find(52, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v1L{44100, channel, 0};
  v1L.configure(found[0]);
  Voice::Voice v1R{44100, channel, 1};
  v1R.configure(found[1]);

  found = preset.find(56, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v2L{44100, channel, 2};
  v2L.configure(found[0]);
  Voice::Voice v2R{44100, channel, 3};
  v2R.configure(found[1]);

  found = preset.find(59, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v3L{44100, channel, 4};
  v3L.configure(found[0]);
  Voice::Voice v3R{44100, channel, 5};
  v3R.configure(found[1]);

  double sampleRate = 44100.0;
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

  int seconds = 10;
  int sampleCount = sampleRate * seconds;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
  AudioBufferList* bufferList = buffer.mutableAudioBufferList;
  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(Float);
  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(Float);
  float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
  float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

  std::vector<AUValue> samples;
  for (auto index = 0; index < sampleCount; ++index) {
    auto s1L = v1L.renderSample();
    auto s2L = v2L.renderSample();
    auto s3L = v3L.renderSample();

    auto s1R = v1R.renderSample();
    auto s2R = v2R.renderSample();
    auto s3R = v3R.renderSample();

    AUValue sL = (s1L + s2L + s3L) / 3.0;
    AUValue sR = (s1R + s2R + s3R) / 3.0;

    *samplesLeft++ = sL;
    *samplesRight++ = sR;

    if (index == 0 || index == sampleCount - 1) {
      samples.push_back(s1L);
      samples.push_back(s2L);
      samples.push_back(s3L);
    }
    else if (index == int(sampleCount * 0.3)) {
      // Enable vibrato
      v1L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
      v1R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
      v2L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
      v2R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
      v3L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
      v3R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
    }
    else if (index == int(sampleCount * 0.5)) {
      // Disable vibrato
      v1L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
      v1R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
      v2L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
      v2R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
      v3L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
      v3R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
    }
    else if (index == int(sampleCount * 0.7)) {
      samples.push_back(s1L);
      samples.push_back(s2L);
      samples.push_back(s3L);

      v1L.releaseKey();
      v1R.releaseKey();
      v2L.releaseKey();
      v2R.releaseKey();
      v3L.releaseKey();
      v3R.releaseKey();
    }
  }

  XCTAssertEqual(9, samples.size());
  XCTAssertEqualWithAccuracy(0.0, samples[0], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[1], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[2], epsilon);

  XCTAssertEqualWithAccuracy(0.045224, samples[3], epsilon);
  XCTAssertEqualWithAccuracy(0.077737, samples[4], epsilon);
  XCTAssertEqualWithAccuracy(-0.045403, samples[5], epsilon);

  XCTAssertEqualWithAccuracy(0.0, samples[6], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[7], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[8], epsilon);

  [self playSamples: buffer count: sampleCount];
}

- (void)playSamples:(AVAudioPCMBuffer*)buffer count:(int)sampleCount
{
  if (!self.playAudio) return;

  buffer.frameLength = sampleCount;

  NSError* error = nil;
  self.audioFileURL = [NSURL fileURLWithPath: [self pathForTemporaryFile] isDirectory:NO];
  AVAudioFile* audioFile = [[AVAudioFile alloc] initForWriting:self.audioFileURL
                                                      settings:[[buffer format] settings]
                                                  commonFormat:AVAudioPCMFormatFloat32
                                                   interleaved:false
                                                         error:&error];
  if (error) {
    XCTFail(@"failed with error: %@", error);
    return;
  }

  [audioFile writeFromBuffer:buffer error:&error];
  if (error) {
    XCTFail(@"failed with error: %@", error);
    return;
  }

  audioFile = nil;

  self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.audioFileURL error:&error];
  if (self.player == nullptr && error != nullptr) {
    XCTFail(@"Expectation Failed with error: %@", error);
    return;
  }

  self.player.delegate = self;
  self.expectation = [self expectationWithDescription:@"AVAudioPlayer finished"];
  [self.player play];
  [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *err) {
    if (err) {
      XCTFail(@"Expectation Failed with error: %@", err);
    }
  }];
}

- (NSString *)pathForTemporaryFile
{
  NSString *  result;
  CFUUIDRef   uuid;
  CFStringRef uuidStr;

  uuid = CFUUIDCreate(NULL);
  assert(uuid != NULL);

  uuidStr = CFUUIDCreateString(NULL, uuid);
  assert(uuidStr != NULL);

  result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf", uuidStr]];
  assert(result != nil);

  CFRelease(uuidStr);
  CFRelease(uuid);

  return result;
}

- (void)testLoopingModes {
  Voice::State::State state{contexts.context3.makeState(60, 32)};
  Voice::Voice voice{44100.0, contexts.context3.channel(), 0};

  XCTAssertEqual(Voice::Voice::LoopingMode::none, voice.loopingMode());
  voice.state().setValue(Voice::State::State::Index::sampleModes, -1);
  XCTAssertEqual(Voice::Voice::LoopingMode::none, voice.loopingMode());
  voice.state().setValue(Voice::State::State::Index::sampleModes, 1);
  XCTAssertEqual(Voice::Voice::LoopingMode::activeEnvelope, voice.loopingMode());
  voice.state().setValue(Voice::State::State::Index::sampleModes, 2);
  XCTAssertEqual(Voice::Voice::LoopingMode::none, voice.loopingMode());
  voice.state().setValue(Voice::State::State::Index::sampleModes, 3);
  XCTAssertEqual(Voice::Voice::LoopingMode::duringKeyPress, voice.loopingMode());
  voice.state().setValue(Voice::State::State::Index::sampleModes, 4);
  XCTAssertEqual(Voice::Voice::LoopingMode::none, voice.loopingMode());
}

@end
