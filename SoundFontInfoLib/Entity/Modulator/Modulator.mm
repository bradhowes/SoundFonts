// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>

#include "Modulator.hpp"

using namespace SF2::Entity::Modulator;

std::array<Modulator, 10> const Modulator::defaults {
    Modulator(Source(0x0502), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    Modulator(Source(0x0102), Generator::Index::initialFilterCutoff, -2400, Source(0), Transform(0)),
    Modulator(Source(0x000D), Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
    Modulator(Source(0x0081), Generator::Index::vibratoLFOToPitch, 50, Source(0), Transform(0)),
    Modulator(Source(0x0582), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    Modulator(Source(0x028A), Generator::Index::initialAttenuation, 1000, Source(0), Transform(0)),
    Modulator(Source(0x058B), Generator::Index::initialAttenuation, 960, Source(0), Transform(0)),
    Modulator(Source(0x00DB), Generator::Index::reverbEffectSend, 200, Source(0), Transform(0)),
    Modulator(Source(0x00DD), Generator::Index::chorusEffectSend, 200, Source(0), Transform(0)),
    Modulator(Source(0x020E), Generator::Index::initialPitch, 12700, Source(0x0010), Transform(0))
};

void
Modulator::dump(const std::string& indent, int index) const
{
    std::cout << indent << '[' << index
    << "] src: " << sfModSrcOper
    << " dest: " << Generator::Definition::definition(sfModDestOper).name()
    << " amount: " << modAmount
    << " op: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper
    << std::endl;
}
