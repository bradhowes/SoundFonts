// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "DSP.hpp"
#include "MIDI.hpp"

using namespace SF2::Render;

std::array<double, MIDI::MaxNote + 1> MIDI::standardNoteFrequencies_ = [] {
    auto init = decltype(MIDI::standardNoteFrequencies_){};
    auto frequency = DSP::LowestNoteFrequency;
    auto scale = ::std::pow(2.0, 1.0 / 12.0);
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = frequency;
        frequency *= scale;
    }
    return init;
}();
