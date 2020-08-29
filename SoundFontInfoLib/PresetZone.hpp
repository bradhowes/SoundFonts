// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "InstrumentCollection.hpp"
#include "SFBag.hpp"
#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class Configuration;

class PresetZone : public Zone {
public:
    PresetZone(SFFile const& file, InstrumentCollection const& instruments, SFBag const& bag) :
    Zone(file.presetZoneGenerators.slice(bag.generatorIndex(), bag.generatorCount()),
         file.presetZoneModulators.slice(bag.modulatorIndex(), bag.modulatorCount()),
         SFGenIndex::instrument),
    instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
    {}

    // Preset values only refine those from instrument
    void refine(Configuration& configuration) const { Zone::refine(configuration); }

    Instrument const& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
    Instrument const* instrument_;
};

}
