// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Instrument.hpp"
#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class PresetZone : public Zone {
public:
    PresetZone(SFFile const& file, InstrumentCollection const& instruments, SFBag const& bag, size_t index) :
    Zone(file.presetZoneGenerators.slice(bag.generatorIndex(), bag.generatorCount()),
         file.presetZoneModulators.slice(bag.modulatorIndex(), bag.modulatorCount()),
         SFGenIndex::instrument, index),
    instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
    {}

    Instrument const& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
    Instrument const* instrument_;
};

class Preset {
public:
    using PresetZoneCollection = ZoneCollection<PresetZone>;
    using ZonePair = std::pair<std::reference_wrapper<PresetZone const>, std::reference_wrapper<InstrumentZone const>>;
    using Matches = std::vector<ZonePair>;

    Preset(SFFile const& file, InstrumentCollection const& instruments, uint16_t presetIndex) :
    configuration_{file.presets[presetIndex]},
    zones_{size_t(configuration_.zoneCount())}
    {
        auto index = configuration_.zoneIndex();
        auto count = configuration_.zoneCount();
        while (count-- > 0) {
            auto const& bag = file.presetZones[index];
            if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
                zones_.emplace_back(file, instruments, bag, index++);
            }
        }
    }

    Matches find(int key, int velocity) const {
        Matches zonePairs;
        for (PresetZone const& presetZone : zones_.find(key, velocity)) {
            presetZone.dump("--");
            for (InstrumentZone const& instrumentZone : presetZone.instrument().find(key, velocity)) {
                zonePairs.emplace_back(presetZone, instrumentZone);
            }
        }

        return zonePairs;
    }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    PresetZone const* globalZone() const { return zones_.global(); }

private:
    SFPreset const& configuration_;
    PresetZoneCollection zones_;
};

class PresetCollection
{
public:
    PresetCollection(SFFile const& file, InstrumentCollection const& instruments) :
    presets_{}
    {
        presets_.reserve(file.presets.size());
        // Do *not* process the last record. It is a sentinal used only for bag calculations.
        for (auto index = 0; index < file.presets.size() - 1; ++index) {
            presets_.emplace_back(file, instruments, index);
        }
    }

    Preset const& at(size_t index) const { return presets_.at(index); }

private:
    std::vector<Preset> presets_;
};

}
