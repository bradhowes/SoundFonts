// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"

using namespace SF2::Render;

Instrument::Instrument(const IO::File& file, const Entity::Instrument& cfg) : cfg_{cfg}, zones_{size_t(cfg_.zoneCount())}
{
    for (const Entity::Bag& bag : file.instrumentZones().slice(cfg_.firstZoneIndex(), cfg_.zoneCount())) {
        if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
            zones_.add(file, bag);
        }
    }
}
