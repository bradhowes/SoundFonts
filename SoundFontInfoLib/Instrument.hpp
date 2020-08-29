// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "InstrumentZone.hpp"
#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class Instrument
{
public:
    using InstrumentZoneCollection = ZoneCollection<InstrumentZone>;

    Instrument(SFFile const& file, SFInstrument const& cfg) :
    cfg_{cfg},
    zones_{size_t(cfg_.zoneCount())}
    {
        for (SFBag const& bag : file.instrumentZones.slice(cfg_.zoneIndex(), cfg_.zoneCount())) {
            if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
                zones_.emplace_back(file, bag);
            }
        }
    }

    InstrumentZoneCollection::Matches find(int key, int velocity) const { return zones_.find(key, velocity); }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    InstrumentZone const* globalZone() const { return zones_.global(); }
    SFInstrument const& configuration() const { return cfg_; }

private:
    SFInstrument const& cfg_;
    InstrumentZoneCollection zones_;
};

}
