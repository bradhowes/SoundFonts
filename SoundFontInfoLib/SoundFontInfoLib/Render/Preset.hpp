// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"
#include "Render/PresetZone.hpp"
#include "Render/Voice/Config.hpp"
#include "Render/WithZones.hpp"

namespace SF2::Render {

/**
 Represents a preset that knows how to emit sounds for MIDI events when it is active.

 A preset is made up of a collection of zones, where each zone defines a MIDI key and velocity range that it applies to
 and an instrument that determines the sound to produce. Note that zones can overlap, so one MIDI key event can cause
 multiple instruments to play, each of which will require its own Voice instance to render.
 */
class Preset : public WithZones<PresetZone, Entity::Preset> {
public:
  using PresetZoneCollection = WithZoneCollection;
  using VoiceConfigCollection = std::vector<Voice::Config>;

  /**
   Construct new Preset from SF2 entities

   @param file the SF2 file that is loaded
   @param instruments the collection of instruments that apply to the preset
   @param config the SF2 preset definition
   */
  Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& config) :
  WithZones<PresetZone, Entity::Preset>(config.zoneCount(), config) {
    for (const Entity::Bag& bag : file.presetZones().slice(config.firstZoneIndex(), config.zoneCount())) {
      zones_.add(Entity::Generator::Index::instrument,
                 file.presetZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
                 file.presetZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
                 instruments);
    }
  }

  /**
   Locate preset/instrument zones for the given key/velocity values. There can be more than one match, often due to
   separate left/right channels for rendering. Each match will require its own Voice for rendering.

   @param key the MIDI key to filter with
   @param velocity the MIDI velocity to filter with
   @returns vector of Voice:Config instances containing the zones to use
   */
  VoiceConfigCollection find(int key, int velocity) const {
    VoiceConfigCollection zonePairs;

    // Obtain the preset zones that match the key/velocity combination
    for (const PresetZone& presetZone : zones_.filter(key, velocity)) {

      // For each preset zone, scan to find an instrument to use for rendering
      const Instrument& instrument = presetZone.instrument();
      auto instrumentGlobal = instrument.globalZone();
      for (const InstrumentZone& instrumentZone : instrument.filter(key, velocity)) {

        // Record a new Voice::Config with the preset/instrument zones to use for rendering
        zonePairs.emplace_back(presetZone, globalZone(), instrumentZone, instrumentGlobal, key, velocity);
      }
    }

    return zonePairs;
  }
};

} // namespace SF2::Render
