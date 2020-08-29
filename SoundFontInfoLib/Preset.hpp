// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Instrument.hpp"
#include "PresetZone.hpp"
#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class Preset {
public:
    using PresetZoneCollection = ZoneCollection<PresetZone>;

    struct ZonePair {
        PresetZone const& presetZone;
        PresetZone const* presetGlobal;
        InstrumentZone const& instrumentZone;
        InstrumentZone const* instrumentGlobal;

        ZonePair(PresetZone const& pz, PresetZone const* pg, InstrumentZone const& iz, InstrumentZone const* ig)
        : presetZone{pz}, presetGlobal{pg}, instrumentZone{iz}, instrumentGlobal{ig} {}

        void apply(Configuration& configuration) {

            // Instrument first for override absolute values
            if (instrumentGlobal != nullptr) instrumentGlobal->apply(configuration);
            instrumentZone.apply(configuration);

            // Preset values only refine those from instrument
            if (presetGlobal != nullptr) presetGlobal->refine(configuration);
            presetZone.refine(configuration);
        }
    };

    using Matches = std::vector<ZonePair>;

    Preset(SFFile const& file, InstrumentCollection const& instruments, SFPreset const& cfg) :
    cfg_{cfg},
    zones_{size_t(cfg_.zoneCount())}
    {
        for (SFBag const& bag : file.presetZones.slice(cfg_.zoneIndex(), cfg_.zoneCount())) {
            if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
                zones_.emplace_back(file, instruments, bag);
            }
        }
    }

    Matches find(int key, int velocity) const {
        Matches zonePairs;
        for (PresetZone const& presetZone : zones_.find(key, velocity)) {
            Instrument const& instrument = presetZone.instrument();
            InstrumentZone const* instrumentGlobal = instrument.globalZone();
            for (InstrumentZone const& instrumentZone : instrument.find(key, velocity)) {
                zonePairs.emplace_back(presetZone, globalZone(), instrumentZone, instrumentGlobal);
            }
        }

        return zonePairs;
    }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    PresetZone const* globalZone() const { return zones_.global(); }
    SFPreset const& configuration() const { return cfg_; }

private:
    SFPreset const& cfg_;
    PresetZoneCollection zones_;
};

}
