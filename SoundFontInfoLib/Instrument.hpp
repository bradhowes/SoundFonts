// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class InstrumentZone : public Zone {
public:
    InstrumentZone(SFFile const& file, SFBag const& bag) :
    Zone(file.instrumentZoneGenerators.slice(bag.generatorIndex(), bag.generatorCount()),
         file.instrumentZoneModulators.slice(bag.modulatorIndex(), bag.modulatorCount()),
         SFGenIndex::sampleID),
    sample_{isGlobal() ? nullptr : &file.samples[resourceLink()]},
    sampleData_{file.sampleData}
    {}

    void apply(Configuration& configuration) const { Zone::apply(configuration); }

private:
    SFSample const* sample_;
    uint8_t const* sampleData_;
};

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

class InstrumentCollection
{
public:

    InstrumentCollection(SFFile const& file) :
    instruments_{}
    {
        // Do *not* process the last record. It is a sentinal used only for bag calculations.
        auto count = file.instruments.size() - 1;
        instruments_.reserve(count);
        for (SFInstrument const& configuration : file.instruments.slice(0, count)) {
            instruments_.emplace_back(file, configuration);
        }
    }

    Instrument const& at(size_t index) const { return instruments_.at(index); }

private:
    std::vector<Instrument> instruments_;
};

}
