// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../IO/File.hpp"

#include "PresetZone.hpp"

namespace SF2 {
namespace Render {

class Preset {
public:
    using PresetZoneCollection = ZoneCollection<Render::PresetZone>;

    struct ZonePair {
        const Render::PresetZone& presetZone;
        Render::PresetZone const* presetGlobal;
        const Render::InstrumentZone& instrumentZone;
        Render::InstrumentZone const* instrumentGlobal;

        ZonePair(const Render::PresetZone& pz, PresetZone const* pg, const InstrumentZone& iz, InstrumentZone const* ig)
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

    Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& cfg) : cfg_{cfg}, zones_{size_t(cfg_.zoneCount())}
    {
        for (const Entity::Bag& bag : file.presetZones().slice(cfg_.zoneIndex(), cfg_.zoneCount())) {
            if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
                zones_.emplace_back(file, instruments, bag);
            }
        }
    }

    Matches find(int key, int velocity) const {
        Matches zonePairs;
        for (const PresetZone& presetZone : zones_.find(key, velocity)) {
            const Instrument& instrument = presetZone.instrument();
            InstrumentZone const* instrumentGlobal = instrument.globalZone();
            for (const InstrumentZone& instrumentZone : instrument.find(key, velocity)) {
                zonePairs.emplace_back(presetZone, globalZone(), instrumentZone, instrumentGlobal);
            }
        }

        return zonePairs;
    }

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    PresetZone const* globalZone() const { return zones_.global(); }
    const Entity::Preset& configuration() const { return cfg_; }

private:
    const Entity::Preset& cfg_;
    PresetZoneCollection zones_;
};

}
}
