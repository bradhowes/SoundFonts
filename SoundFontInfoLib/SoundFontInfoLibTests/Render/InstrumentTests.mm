// Copyright © 2020 Brad Howes. All rights reserved.

#include "SampleBasedContexts.hpp"

#include "IO/File.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Preset.hpp"
#include "Render/Voice/State/Config.hpp"
#include "Render/Voice/State/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Render::Voice;

@interface InstrumentTests : XCTestCase
@end

@implementation InstrumentTests {
  SampleBasedContexts contexts;
}

- (void)testRolandPianoInstrument {
  auto& file{contexts.context3.file()};

  Instrument instrument(file, file.instruments()[0]);
  XCTAssertEqual(std::string("Instrument6"), instrument.configuration().name());

  XCTAssertTrue(instrument.hasGlobalZone());

  auto zones = instrument.filter(64, 10);
  XCTAssertEqual(2, zones.size());
  XCTAssertFalse(zones[0].get().isGlobal());
  XCTAssertNotEqual(nullptr, &zones[0].get().sampleSource());

  InstrumentCollection instruments;
  instruments.build(file);
  Preset preset(file, instruments, file.presets()[0]);
  auto found = preset.find(64, 64);

  MIDI::Channel channel;
  State::State left{44100, channel};
  left.prepareForVoice(found[0]);
  XCTAssertEqual(-500, left.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, left.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, left.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(23, left.unmodulated(Entity::Generator::Index::sampleID));

  State::State right{44100.0, channel};
  right.prepareForVoice(found[1]);
  XCTAssertEqual(500, right.unmodulated(Entity::Generator::Index::pan));
  XCTAssertEqual(2041, right.unmodulated(Entity::Generator::Index::releaseVolumeEnvelope));
  XCTAssertEqual(9023, right.unmodulated(Entity::Generator::Index::initialFilterCutoff));
  XCTAssertEqual(22, right.unmodulated(Entity::Generator::Index::sampleID));
}

@end
