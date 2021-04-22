// Copyright © 2020 Brad Howes. All rights reserved.

#include "Entity/Modulator/Modulator.hpp"
#include "Render/MIDI/Channel.hpp"
#include "Render/Voice/State.hpp"

#include "Render/Modulator.hpp"

using namespace SF2;
using namespace SF2::Render;

namespace EntityMod = Entity::Modulator;

Modulator::Modulator(size_t index, const EntityMod::Modulator& configuration, const Voice::State& state) :
configuration_{configuration},
index_{index},
sourceTransform_{configuration.source()},
amountTransform_{configuration.amountSource()},
sourceValue_{SourceValue(configuration, state, 1)},
amountValue_{SourceValue(configuration, state, 0)}
{
    ;
}

std::function<int()>
Modulator::SourceValue(const EntityMod::Modulator& configuration, const Voice::State& state, int noneValue)
{
    using GI = EntityMod::Source::GeneralIndex;
    const auto& source = configuration.source();
    if (source.isContinuousController()) {
        return std::bind(&MIDI::Channel::continuousControllerValue, state.channel(), source.continuousIndex());
    }
    switch (source.generalIndex()) {
        case GI::none: return [noneValue](){ return noneValue; };
        case GI::noteOnVelocity: return std::bind(&Voice::State::velocity, state);
        case GI::noteOnKeyValue: return std::bind(&Voice::State::key, state);
        case GI::polyPressure: return std::bind(&MIDI::Channel::keyPressure, state.channel(), state.key());
        case GI::channelPressure: return std::bind(&MIDI::Channel::channelPressure, state.channel());
        case GI::pitchWheel: return std::bind(&MIDI::Channel::pitchWheelValue, state.channel());
        case GI::pitchWheelSensitivity: return std::bind(&MIDI::Channel::pitchWheelSensitivity, state.channel());
        case GI::link: return nullptr;
    }
}

double
Modulator::value() const {
    return sourceTransform_.value(sourceValue_()) * configuration_.amount() * amountTransform_.value(amountValue_());
}
