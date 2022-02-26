// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>
#include <sstream>

#include "Modulator.hpp"

using namespace SF2::Entity::Modulator;

const std::array<Modulator, Modulator::size> Modulator::defaults {
  // MIDI key velocity to initial attenuation (8.4.1)
  Modulator(Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity).negative().concave().make(),
            Generator::Index::initialAttenuation,
            960, Source{0}, Transform{0}),
  // MIDI key velocity to initial filter cutoff (8.4.2)
  Modulator(Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity).negative().linear().make(),
            Generator::Index::initialFilterCutoff, -2400, Source(0), Transform(0)),
  // MIDI channel pressure to vibrato LFO pitch depth (8.4.3)
  Modulator(Source::Builder::GeneralController(Source::GeneralIndex::channelPressure).linear().make(),
            Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
  // MIDI CC 1 to vibrato LFO pitch depth (8.4.4)
  Modulator(Source::Builder::ContinuousController(1).linear().make(),
            Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
  // MIDI CC 7 to initial attenuation (NOTE spec says Source(0x0582) which gives CC 2) (8.4.5)
  Modulator(Source::Builder::ContinuousController(7).negative().concave().make(),
            Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
  // MIDI CC 10 to pan position (8.4.6)
  Modulator(Source::Builder::ContinuousController(10).bipolar().linear().make(),
            Generator::Index::pan, 1000, Source(0), Transform(0)),
  // MIDI CC 11 to initial attenuation (8.4.7)
  Modulator(Source::Builder::ContinuousController(11).negative().concave().make(),
            Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
  // MIDI CC 91 to reverb amount (8.4.8)
  Modulator(Source::Builder::ContinuousController(91).make(),
            Generator::Index::reverbEffectSend, 200, Source(0), Transform(0)),
  // MIDI CC 93 to chorus amount (8.4.9)
  Modulator(Source::Builder::ContinuousController(93).make(),
            Generator::Index::chorusEffectSend, 200, Source(0), Transform(0)),
  // MIDI pitch wheel to "initial pitch" (8.4.10). Follow FluidSynth here: as there is no "initial pitch" generator in
  // the spec, link the modulator to `fineTune` instead. That way it can be overridden by a preset and/or instrument.
  Modulator(Source::Builder::GeneralController(Source::GeneralIndex::pitchWheel).bipolar().make(),
            Generator::Index::fineTune, 12700,
            Source::Builder::GeneralController(Source::GeneralIndex::pitchWheelSensitivity).make(), Transform(0))
};

void
Modulator::dump(const std::string& indent, size_t index) const
{
  std::cout << indent << '[' << index << "] " << description() << std::endl;
}

std::string
Modulator::description() const
{
  std::ostringstream os;
  os << "Sv: " << sfModSrcOper << " Av: " << sfModAmtSrcOper << " dest: ";
  if (hasModulatorDestination()) {
    os << "mod[" << linkDestination() << "]";
  }
  else {
    os << Generator::Definition::definition(generatorDestination()).name();
  }
  
  os << " amount: " << modAmount << " trans: " << transform();
  
  return os.str();
}
