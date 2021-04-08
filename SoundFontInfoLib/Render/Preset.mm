// Copyright © 2020 Brad Howes. All rights reserved.

#include "Render/Preset.hpp"

using namespace SF2::Render;

Preset::Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& cfg)
: cfg_{cfg}, zones_{size_t(cfg_.zoneCount())}
{
    for (const Entity::Bag& bag : file.presetZones().slice(cfg_.zoneIndex(), cfg_.zoneCount())) {
        if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
            zones_.add(file, instruments, bag);
        }
    }
}

Preset::Matches
Preset::find(int key, int velocity) const
{
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
