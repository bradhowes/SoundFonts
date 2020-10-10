// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"

using namespace SF2;

Instrument::Instrument(SFFile const& file, SFInstrument const& cfg) : cfg_{cfg}, zones_{size_t(cfg_.zoneCount())}
{
    for (SFBag const& bag : file.instrumentZones().slice(cfg_.zoneIndex(), cfg_.zoneCount())) {
        if (bag.generatorCount() != 0 || bag.modulatorCount() != 0) {
            zones_.emplace_back(file, bag);
        }
    }
}
