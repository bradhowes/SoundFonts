// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"
#include "Render/PresetZone.hpp"
#include "Render/VoiceState.hpp"
#include "Render/WithZones.hpp"

namespace SF2 {
namespace Render {

/**
 Represents a preset that knows how to emit sounds for MIDI events when it is active.

 A preset is made up of a collection of zones, where each zone defines a MIDI key and velocity range that it applies to
 and an instrument that determines the sound to produce. Note that zones can overlap, so one MIDI event can cause
 multiple instruments to play, each which will require a Voice instance to render.
 */
class Preset : public WithZones<PresetZone, Entity::Preset> {
public:
    using PresetZoneCollection = WithZoneCollection;

    /**
     A combination of preset zone and instrument zone (plus optional global zones for each). One zone pair represents
     the configuration that should apply to the state of one voice.
     */
    class ZonePair {
    public:

        /**
         Construct a preset/instrument pair

         @param presetZone the PresetZone that matched a key/velocity search
         @param presetGlobal the global PresetZone to apply (optional -- nullptr if no global)
         @param instrumentZone the InstrumentZone that matched a key/velocity search
         @param instrumentGlobal the global InstrumentZone to apply (optional -- nullptr if no global)
         */
        ZonePair(const PresetZone& presetZone, const PresetZone* presetGlobal,
                 const InstrumentZone& instrumentZone, const InstrumentZone* instrumentGlobal) :
        presetZone_{presetZone}, presetGlobal_{presetGlobal}, instrumentZone_{instrumentZone},
        instrumentGlobal_{instrumentGlobal} {}

        /**
         Update a VoiceState with the various zone configurations.

         @param state the VoiceState to update
         */
        void apply(VoiceState& state) {

            // Instrument zones first to set absolute values
            if (instrumentGlobal_ != nullptr) instrumentGlobal_->apply(state);
            instrumentZone_.apply(state);

            // Preset values to refine those from instrument
            if (presetGlobal_ != nullptr) presetGlobal_->refine(state);
            presetZone_.refine(state);
        }

    private:
        const PresetZone& presetZone_;
        PresetZone const* presetGlobal_;

        const InstrumentZone& instrumentZone_;
        InstrumentZone const* instrumentGlobal_;

    };

    using Matches = std::vector<ZonePair>;

    /**
     Construct new Preset from SF2 entities

     @param file the SF2 file that is loaded
     @param instruments the collection of instruments that apply to the preset
     @param configuration the SF2 preset definition
     */
    Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& configuration) :
    WithZones<PresetZone, Entity::Preset>(configuration.zoneCount(), configuration) {
        for (const Entity::Bag& bag : file.presetZones().slice(configuration.firstZoneIndex(),
                                                               configuration.zoneCount())) {
            zones_.add(file, bag, instruments);
        }
    }

    /**
     Locate preset/instrument pairs for the given key/velocity values.

     @param key the MIDI key to filter with
     @param velocity the MIDI velocity to filter with
     @returns vector of matching preset/instrument pairs
     */
    Matches find(UByte key, UByte velocity) const {
        Matches zonePairs;
        for (const PresetZone& presetZone : zones_.filter(key, velocity)) {
            const Instrument& instrument = presetZone.instrument();
            const InstrumentZone* instrumentGlobal = instrument.globalZone();
            for (const InstrumentZone& instrumentZone : instrument.filter(key, velocity)) {
                zonePairs.emplace_back(presetZone, globalZone(), instrumentZone, instrumentGlobal);
            }
        }

        return zonePairs;
    }
};

} // namespace Render
} // namespace SF2
