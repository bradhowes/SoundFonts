// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "IO/File.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Preset.hpp"
#include "Render/Voice/Config.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface InstrumentTests : XCTestCase
@end

@implementation InstrumentTests

- (void)testRolandPianoInstrument {
  NSURL* url = [urls objectAtIndex:3];
  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd, fileSize);

  Instrument instrument(file, file.instruments()[0]);
  XCTAssertEqual(std::string("Instrument6"), instrument.configuration().name());

  XCTAssertTrue(instrument.hasGlobalZone());
  auto globalZone = instrument.globalZone();
  XCTAssertTrue(globalZone);
  XCTAssertEqual(nullptr, globalZone.value()->sampleBuffer());

  auto zones = instrument.filter(64, 10);
  XCTAssertEqual(2, zones.size());
  XCTAssertFalse(zones[0].get().isGlobal());
  XCTAssertNotEqual(nullptr, zones[0].get().sampleBuffer());

  InstrumentCollection instruments(file);
  Preset preset(file, instruments, file.presets()[0]);
  auto found = preset.find(64, 64);

  MIDI::Channel channel;
  Voice::State left{44100.0, channel, found[0]};
  XCTAssertEqual(-500, left.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, left.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, left.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(23, left.unmodulated(Entity::Generator::Index::sampleID));

  Voice::State right{44100.0, channel, found[1]};
  XCTAssertEqual(500, right.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, right.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, right.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(22, right.unmodulated(Entity::Generator::Index::sampleID));
}

@end
