// Copyright © 2020 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "IO/File.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/Voice/Voice.hpp"

using namespace SF2;
using namespace SF2::Render;

static NSArray<NSURL*>* urls = SF2Files.allResources;

@interface VoiceTests : XCTestCase <AVAudioPlayerDelegate>
@property (nonatomic) bool playAudio;
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) XCTestExpectation* expectation;
@property (nonatomic, retain) NSURL* audioFileURL;
@end

@implementation VoiceTests

- (void)setUp {
  self.playAudio = YES;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
  [self.expectation fulfill];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
}

- (void)testRolandPianoRender {
  double epsilon = 0.000001;

  NSURL* url = [urls objectAtIndex:3];
  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd, fileSize);

  MIDI::Channel channel;
  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[0]);

  auto found = preset.find(69, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v1L{44100, channel, found[0]};
  Voice::Voice v1R{44100, channel, found[1]};

  found = preset.find(73, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v2L{44100, channel, found[0]};
  Voice::Voice v2R{44100, channel, found[1]};

  found = preset.find(76, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v3L{44100, channel, found[0]};
  Voice::Voice v3R{44100, channel, found[1]};

  double sampleRate = 44100.0;
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

  auto renderLR = [&](auto& left, auto& right) {
    for (auto index = 0; index < voiceSampleCount; ++index) {
      AUValue sample = left.render();
      *samplesLeft++ = sample;
      *samplesRight++ = right.render();
      if (index == 0 || index == voiceSampleCount - 1) {
        samples.push_back(sample);
      }
      else if (index == keyReleaseCount) {
        samples.push_back(sample);
        left.keyReleased();
        right.keyReleased();
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

  NSURL* url = [urls objectAtIndex:2];
  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd, fileSize);

  MIDI::Channel channel;
  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[19]);

  auto found = preset.find(52, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v1L{44100, channel, found[0]};
  Voice::Voice v1R{44100, channel, found[1]};

  found = preset.find(56, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v2L{44100, channel, found[0]};
  Voice::Voice v2R{44100, channel, found[1]};

  found = preset.find(59, 127);
  XCTAssertEqual(found.size(), 2);
  Voice::Voice v3L{44100, channel, found[0]};
  Voice::Voice v3R{44100, channel, found[1]};

  double sampleRate = 44100.0;
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

  int seconds = 10;
  int sampleCount = sampleRate * seconds;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
  AudioBufferList* bufferList = buffer.mutableAudioBufferList;
  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);
  float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
  float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

  std::vector<AUValue> samples;
  for (auto index = 0; index < sampleCount; ++index) {
    auto s1L = v1L.render();
    auto s2L = v2L.render();
    auto s3L = v3L.render();

    auto s1R = v1R.render();
    auto s2R = v2R.render();
    auto s3R = v3R.render();

    AUValue sL = (s1L + s2L + s3L) / 3.0;
    AUValue sR = (s1R + s2R + s3R) / 3.0;

    *samplesLeft++ = sL;
    *samplesRight++ = sR;

    if (index == 0 || index == sampleCount - 1) {
      samples.push_back(s1L);
      samples.push_back(s2L);
      samples.push_back(s3L);
    }
    else if (index == int(sampleCount * 0.7)) {
      samples.push_back(s1L);
      samples.push_back(s2L);
      samples.push_back(s3L);

      v1L.keyReleased();
      v1R.keyReleased();
      v2L.keyReleased();
      v2R.keyReleased();
      v3L.keyReleased();
      v3R.keyReleased();
    }
  }

  XCTAssertEqual(9, samples.size());
  XCTAssertEqualWithAccuracy(0.0, samples[0], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[1], epsilon);
  XCTAssertEqualWithAccuracy(0.0, samples[2], epsilon);

  XCTAssertEqualWithAccuracy(-0.239043, samples[3], epsilon);
  XCTAssertEqualWithAccuracy(-0.045543, samples[4], epsilon);
  XCTAssertEqualWithAccuracy( 0.016368, samples[5], epsilon);

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
  [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
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

@end
