// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/VoiceState.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

/**
 A specialization of a Zone for a Preset. Non-global Preset zones refer to an Instrument.
 */
class PresetZone : public Zone {
public:

    /**
     Construct new zone from entity in file.

     @param file the file to work with
     @param instruments to collection of instruments found in the file
     @param bag the zone definition
     */
    PresetZone(const IO::File& file, const Entity::Bag& bag, const Render::InstrumentCollection& instruments) :
    Zone(file.presetZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
         file.presetZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
         Entity::Generator::Index::instrument),
    instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
    {}

    /**
     Apply the zone generator values to the given voice state. Unlike instrument zones, those of a Preset only refine
     existing values.

     @param state the state to update
     */
    void refine(Render::VoiceState& state) const { Zone::refine(state); }

    /// @returns the Instrument configured for this zone
    const Render::Instrument& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
    const Render::Instrument* instrument_;
};

} // namespace Render
} // namespace SF2
