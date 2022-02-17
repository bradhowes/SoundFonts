// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "IO/File.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "SampleBasedTestCase.h"

using namespace SF2;
using namespace SF2::Render;

@interface PresetTests : SampleBasedTestCase
@end

@implementation PresetTests

- (void)testRolandPianoPreset {
  auto file{context3.file()};
  XCTAssertEqual(1, file.presets().size());

  Preset preset{context3.preset()};
  XCTAssertEqual(6, preset.zones().size());

  XCTAssertFalse(preset.hasGlobalZone());

  auto found = preset.find(64, 10);
  XCTAssertEqual(2, found.size());

  MIDI::Channel channel;
  State left{44100, channel};
  left.configure(found[0]);
  XCTAssertEqual(-500, left.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(1902, left.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(7437, left.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(23, left.unmodulated(Entity::Generator::Index::sampleID));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::startAddressOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::startAddressCoarseOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::endAddressOffset));
  XCTAssertEqual(0, left.unmodulated(Entity::Generator::Index::endAddressCoarseOffset));

  State right{44100, channel};
  right.configure(found[1]);
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
