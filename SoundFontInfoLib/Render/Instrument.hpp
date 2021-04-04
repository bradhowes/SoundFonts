// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"

#include "Render/InstrumentZone.hpp"
#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

class Instrument
{
public:
    using InstrumentZoneCollection = ZoneCollection<InstrumentZone>;

    Instrument(const IO::File& file, const Entity::Instrument& cfg);

    InstrumentZoneCollection::Matches find(int key, int velocity) const { return zones_.find(key, velocity); }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    InstrumentZone const* globalZone() const { return zones_.global(); }
    const Entity::Instrument& configuration() const { return cfg_; }

private:
    const Entity::Instrument& cfg_;
    InstrumentZoneCollection zones_;
};

}
}
