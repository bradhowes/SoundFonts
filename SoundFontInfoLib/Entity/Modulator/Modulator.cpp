// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>
#include <sstream>

#include "Modulator.hpp"

using namespace SF2::Entity::Modulator;

std::array<Modulator, Modulator::size> const Modulator::defaults {
    // MIDI key velocity to initial attenuation
    Modulator(Source(0x0502), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    // MIDI key velocity to initial filter cutoff
    Modulator(Source(0x0102), Generator::Index::initialFilterCutoff, -2400, Source(0), Transform(0)),
    // MIDI channel pressure to vibrato LFO pitch depth
    Modulator(Source(0x000D), Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
    // MIDI CC 1 to vibrato LFO pitch depth
    Modulator(Source(0x0081), Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
    // MIDI CC 7 to initial attenuation (NOTE spec uses 0x0582 which gives CC 2)
    Modulator(Source(0x0587), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    // MIDI CC 10 to pan position
    Modulator(Source(0x028A), Generator::Index::pan, 1000, Source(0), Transform(0)),
    // MIDI CC 11 to initial attenuation
    Modulator(Source(0x058B), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    // MIDI CC 91 to reverb amount
    Modulator(Source(0x00DB), Generator::Index::reverbEffectSend, 200, Source(0), Transform(0)),
    // MIDI CC 93 to chorus amount
    Modulator(Source(0x00DD), Generator::Index::chorusEffectSend, 200, Source(0), Transform(0)),
    // MIDI pitch wheel to initial pitch
    Modulator(Source(0x020E), Generator::Index::initialPitch, 12700, Source(0x0010), Transform(0))
};

void
Modulator::dump(const std::string& indent, int index) const
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
