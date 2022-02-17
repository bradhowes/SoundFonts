// Copyright © 2020 Brad Howes. All rights reserved.

#import "SampleBasedTestCase.h"

#include "IO/File.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Preset.hpp"
#include "Render/Config.hpp"
#include "Render/State.hpp"

using namespace SF2;
using namespace SF2::Render;

@interface InstrumentTests : SampleBasedTestCase
@end

@implementation InstrumentTests

- (void)testRolandPianoInstrument {
  auto file = context3.file();

  Instrument instrument(file, file.instruments()[0]);
  XCTAssertEqual(std::string("Instrument6"), instrument.configuration().name());

  XCTAssertTrue(instrument.hasGlobalZone());
  auto globalZone = instrument.globalZone();
  XCTAssertTrue(globalZone);
  XCTAssertEqual(nullptr, globalZone.value()->sampleSource());

  auto zones = instrument.filter(64, 10);
  XCTAssertEqual(2, zones.size());
  XCTAssertFalse(zones[0].get().isGlobal());
  XCTAssertNotEqual(nullptr, zones[0].get().sampleSource());

  InstrumentCollection instruments;
  instruments.build(file);
  Preset preset(file, instruments, file.presets()[0]);
  auto found = preset.find(64, 64);

  MIDI::Channel channel;
  State left{44100, channel};
  found[0].apply(left);
  XCTAssertEqual(-500, left.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, left.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, left.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(23, left.unmodulated(Entity::Generator::Index::sampleID));

  State right{44100.0, channel};
  found[1].apply(right);
  XCTAssertEqual(500, right.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, right.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, right.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(22, right.unmodulated(Entity::Generator::Index::sampleID));
}

@end
