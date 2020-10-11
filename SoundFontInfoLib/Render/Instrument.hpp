// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../IO/File.hpp"

#include "InstrumentZone.hpp"
#include "Zone.hpp"

namespace SF2 {
namespace Render {

class Instrument
{
public:
    using InstrumentZoneCollection = ZoneCollection<InstrumentZone>;

    Instrument(IO::File const& file, Entity::Instrument const& cfg);

    InstrumentZoneCollection::Matches find(int key, int velocity) const { return zones_.find(key, velocity); }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    InstrumentZone const* globalZone() const { return zones_.global(); }
    Entity::Instrument const& configuration() const { return cfg_; }

private:
    Entity::Instrument const& cfg_;
    InstrumentZoneCollection zones_;
};

}
}
