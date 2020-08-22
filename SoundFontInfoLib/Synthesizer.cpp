// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "Synthesizer.hpp"

using namespace SF2;

std::array<double, Synthesizer::MaxMIDINote + 1> Synthesizer::standardNoteFrequencies_ = [] {
    auto init = decltype(Synthesizer::standardNoteFrequencies_){};
    auto frequency = Synthesizer::LowestNoteFrequency;
    auto scale = ::std::pow(2.0, 1.0 / 12.0);
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = frequency;
        frequency *= scale;
    }
    return init;
}();

std::array<double, Synthesizer::MaxCentValue * 2 + 1> Synthesizer::centFrequencyMultiplier_ = [] {
    auto init = decltype(Synthesizer::centFrequencyMultiplier_){};
    auto span = double((init.size() - 1) / 2);
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = ::std::pow(2.0, (index - span) / span);
    }
    return init;
}();

std::array<double, Synthesizer::SineLookupTableSize> Synthesizer::sineLookup_ = [] {
    auto init = decltype(Synthesizer::sineLookup_){};
    auto scale = 1.0 / Synthesizer::SineLookupTableScale;
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = ::std::sin(scale * index);
    }
    return init;
}();
