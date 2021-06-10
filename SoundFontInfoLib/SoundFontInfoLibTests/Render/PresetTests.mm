// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "IO/File.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface PresetTests : XCTestCase
@end

@implementation PresetTests

- (void)testRolandPianoPreset {
  NSURL* url = [urls objectAtIndex:3];
  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd, fileSize);

  XCTAssertEqual(1, file.presets().size());

  MIDI::Channel channel;
  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[0]);
  XCTAssertEqual(6, preset.zones().size());

  XCTAssertFalse(preset.hasGlobalZone());

  auto found = preset.find(64, 10);
  XCTAssertEqual(2, found.size());

  Voice::State left{44100, channel, found[0]};
  XCTAssertEqual(-500, left.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(1902, left.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(7437, left.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(23, left.unmodulated(Entity::Generator::Index::sampleID));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::startAddressOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::startAddressCoarseOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::endAddressOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::endAddressCoarseOffset));

  Voice::State right{44100, channel, found[1]};
  XCTAssertEqual(500, right.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(1902, right.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(7437, right.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(22, right.unmodulated(Entity::Generator::Index::sampleID));
  XCTAssertEqual(0, right.unmodulated(Entity::Generator::Index::startAddressOffset));
  XCTAssertEqual(0, right.unmodulated(Entity::Generator::Index::startAddressCoarseOffset));
  XCTAssertEqual(0, right.unmodulated(Entity::Generator::Index::endAddressOffset));
  XCTAssertEqual(0, right.unmodulated(Entity::Generator::Index::endAddressCoarseOffset));
}

@end
