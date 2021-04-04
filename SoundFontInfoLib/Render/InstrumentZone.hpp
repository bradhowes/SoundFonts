// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../Entity/Bag.hpp"
#include "../IO/File.hpp"

#include "Zone.hpp"

namespace SF2 {
namespace Render {

class Configuration;

class InstrumentZone : public Zone {
public:
    InstrumentZone(const IO::File& file, const Entity::Bag& bag);

    void apply(Configuration& configuration) const { Zone::apply(configuration); }

private:
    Entity::Sample const* sample_;
    IO::Pos sampleDataBegin_;
};

}
}
