// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class InstrumentZone : public Zone {
public:
    InstrumentZone(SFFile const& file, SFBag const& bag, size_t index) :
    Zone(file.instrumentZoneGenerators.slice(bag.generatorIndex(), bag.generatorCount()),
         file.instrumentZoneModulators.slice(bag.modulatorIndex(), bag.modulatorCount()),
         SFGenIndex::sampleID, index),
    sample_{isGlobal() ? nullptr : &file.samples[resourceLink()]},
    sampleData_{file.sampleData}
    {}

private:
    SFSample const* sample_;
    uint8_t const* sampleData_;
};

class Instrument
{
public:
    using InstrumentZoneCollection = ZoneCollection<InstrumentZone>;

    Instrument(SFFile const& file, uint16_t instrumentIndex) :
    configuration_{file.instruments[instrumentIndex]},
    zones_{size_t(configuration_.zoneCount())}
    {
        auto count = configuration_.zoneCount();
        for (auto index = configuration_.zoneIndex(); count-- > 0; ++index) {
            auto const& bag = file.instrumentZones[index];
            if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
                zones_.emplace_back(file, bag, index);
            }
        }
    }

    InstrumentZoneCollection::Matches find(int key, int velocity) const { return zones_.find(key, velocity); }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    Zone const* globalZone() const { return zones_.global(); }
    SFInstrument const& configuration() const { return configuration_; }

private:
    SFInstrument const& configuration_;
    InstrumentZoneCollection zones_;
};

class InstrumentCollection
{
public:
    InstrumentCollection(SFFile const& file) :
    instruments_{}
    {
        instruments_.reserve(file.instruments.size());
        // Do *not* process the last record. It is a sentinal used only for bag calculations.
        for (auto index = 0; index < file.instruments.size() - 1; ++index) {
            instruments_.emplace_back(file, index);
        }
    }

    Instrument const& at(size_t index) const { return instruments_.at(index); }

private:
    std::vector<Instrument> instruments_;
};

}
