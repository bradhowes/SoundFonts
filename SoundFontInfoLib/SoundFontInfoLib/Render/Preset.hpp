// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"
#include "Render/PresetZone.hpp"
#include "Render/Voice/Setup.hpp"
#include "Render/WithZones.hpp"

namespace SF2::Render {

/**
 Represents a preset that knows how to emit sounds for MIDI events when it is active.

 A preset is made up of a collection of zones, where each zone defines a MIDI key and velocity range that it applies to
 and an instrument that determines the sound to produce. Note that zones can overlap, so one MIDI event can cause
 multiple instruments to play, each which will require a Voice instance to render.
 */
class Preset : public WithZones<PresetZone, Entity::Preset> {
public:
    using PresetZoneCollection = WithZoneCollection;

    using Matches = std::vector<Voice::Setup>;

    /**
     Construct new Preset from SF2 entities

     @param file the SF2 file that is loaded
     @param instruments the collection of instruments that apply to the preset
     @param config the SF2 preset definition
     */
    Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& config) :
    WithZones<PresetZone, Entity::Preset>(config.zoneCount(), config) {
        for (const Entity::Bag& bag : file.presetZones().slice(config.firstZoneIndex(), config.zoneCount())) {
            zones_.add(file, bag, instruments);
        }
    }

    /**
     Locate preset/instrument pairs for the given key/velocity values.

     @param key the MIDI key to filter with
     @param velocity the MIDI velocity to filter with
     @returns vector of matching preset/instrument pairs
     */
    Matches find(int key, int velocity) const {
        Matches zonePairs;
        for (const PresetZone& presetZone : zones_.filter(key, velocity)) {
            const Instrument& instrument = presetZone.instrument();
            const InstrumentZone* instrumentGlobal = instrument.globalZone();
            for (const InstrumentZone& instrumentZone : instrument.filter(key, velocity)) {
                zonePairs.emplace_back(presetZone, globalZone(), instrumentZone, instrumentGlobal, key, velocity);
            }
        }

        return zonePairs;
    }
};

} // namespace SF2::Render
