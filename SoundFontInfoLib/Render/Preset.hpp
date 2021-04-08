// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"
#include "Render/PresetZone.hpp"

namespace SF2 {
namespace Render {

/**
 Represents a preset that knows how to emit sounds for MIDI events when it is active.

 A preset is made up of a collection of zones, where each zone defines a MIDI key and velocity range that it applies to
 and an instrument that determines the sound to produce. Note that zones can overlap, so one MIDI event can cause
 multiple instruments to play.
 */
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

    Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& cfg);

    Matches find(int key, int velocity) const;

    bool hasGlobalZone() const { return zones_.hasGlobal(); }
    PresetZone const* globalZone() const { return zones_.global(); }
    const Entity::Preset& configuration() const { return cfg_; }

private:
    const Entity::Preset& cfg_;
    PresetZoneCollection zones_;
};

} // namespace Render
} // namespace SF2
