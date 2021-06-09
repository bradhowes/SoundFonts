// Copyright © 2020 Brad Howes. All rights reserved.

#include <sstream>

#include "Entity/Modulator/Modulator.hpp"
#include "Entity/Modulator/Source.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Voice/State.hpp"

#include "Render/Modulator.hpp"

using namespace SF2;
using namespace SF2::Render;

namespace EntityMod = Entity::Modulator;

Modulator::Modulator(size_t index, const EntityMod::Modulator& configuration, const Voice::State& state) :
configuration_{configuration},
index_{index},
amount_{configuration.amount()},
sourceTransform_{configuration.source()},
amountTransform_{configuration.amountSource()},
sourceValue_{SourceValue(configuration.source(), state)},
amountScale_{SourceValue(configuration.amountSource(), state)}
{
  log_.debug() << "adding " << index << ' ' << configuration.description() << std::endl;
}

Modulator::ValueProc
Modulator::SourceValue(const EntityMod::Source& source, const Voice::State& state)
{
  using GI = EntityMod::Source::GeneralIndex;
  if (source.isContinuousController()) {
    int cc{source.continuousIndex()};
    return [&state, cc](){ return state.channel().continuousControllerValue(cc); };
  }
  switch (source.generalIndex()) {
    case GI::none: return nullptr;
    case GI::noteOnVelocity: return [&state](){ return state.velocity(); };
    case GI::noteOnKeyValue: return [&state](){ return state.key(); };
    case GI::polyPressure: return [&state](){ return state.channel().keyPressure(state.key()); };
    case GI::channelPressure: return [&state](){ return state.channel().channelPressure(); };
    case GI::pitchWheel: return [&state](){ return state.channel().pitchWheelValue(); };
    case GI::pitchWheelSensitivity: return [&state](){ return state.channel().pitchWheelSensitivity(); };
    case GI::link: return nullptr;
  }
}

std::string
Modulator::description() const
{
  std::ostringstream os;
  os << configuration().description();
  return os.str();
}
