// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"

#include "Render/Configuration.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zone.hpp"

namespace SF2 {
namespace Remder {

class PresetZone : public Render::Zone {
public:
    PresetZone(const IO::File& file, const Render::InstrumentCollection& instruments, const Entity::Bag& bag) :
    Zone(file.presetZoneGenerators().slice(bag.generatorIndex(), bag.generatorCount()),
         file.presetZoneModulators().slice(bag.modulatorIndex(), bag.modulatorCount()),
         Entity::GenIndex::instrument),
    instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
    {}

    // Preset values only refine those from instrument
    void refine(Render::Configuration& configuration) const { Zone::refine(configuration); }

    const Render::Instrument& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
    Render::Instrument const* instrument_;
};

}
}
