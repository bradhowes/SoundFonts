// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Index.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {
namespace Sample {

struct PitchControl {
    using Index = Entity::Generator::Index;

    /**
     Construct new instance using information from 'shdr' and current voice state values from generators related to
     sample indices.

     @param state the generator values to use
     */
    PitchControl(const Voice::State& state) {
        modulatorLFOToPitch_ = state.modulated(Index::modulatorLFOToPitch);
        vibratoLFOToPitch_ = state.modulated(Index::vibratoLFOToPitch);
        modulatorEnvelopeToPitch_ = state.modulated(Index::modulatorEnvelopeToPitch);
    }

private:
    double modulatorLFOToPitch_;
    double vibratoLFOToPitch_;
    double modulatorEnvelopeToPitch_;
};

} // namespace Sample
} // namespace Render
} // namespace SF2
