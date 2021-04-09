// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"

#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

class Configuration;

class InstrumentZone : public Zone {
public:
    InstrumentZone(const IO::File& file, const Entity::Bag& bag);

    void apply(VoiceState& state) const { Zone::apply(state); }

private:
    const Entity::SampleHeader* sampleHeader_;
    IO::Pos sampleDataBegin_;
};

} // namespace Render
} // namespace SF2
