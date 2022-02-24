// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"

#include "Render/Zone/Instrument.hpp"
#include "Render/Zone/WithCollectionBase.hpp"

namespace SF2::Render {

/**
 Representation of an `instrument` in an SF2 file. An instrument is made up of one or more zones, where a zone is
 defined as a collection of generators and modulators that apply for a particular MIDI key value and/or velocity.
 All instrument zone generators except the very first must end with generator index #53 `sampleID` which indicates
 which `SampleBuffer` to use to render audio. If the first zone of an instrument does not end with a `sampleID`
 generator, then it is considered to be the one and only `global` zone, with its generators/modulators applied to all
 other zones unless a zone has its own definition.
 */
class Instrument : public Zone::WithCollectionBase<Zone::Instrument, Entity::Instrument>
{
public:
  using CollectionType = CollectionType;

  /**
   Construct new Instrument from SF2 entities

   @param file the SF2 file that was loaded
   @param config the SF2 file entity that defines the instrument
   */
  Instrument(const IO::File& file, const Entity::Instrument& config) :
  Zone::WithCollectionBase<Zone::Instrument, Entity::Instrument>(config.zoneCount(), config) {
    for (const Entity::Bag& bag : file.instrumentZones().slice(config.firstZoneIndex(), config.zoneCount())) {
      zones_.add(Entity::Generator::Index::sampleID,
                 file.instrumentZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
                 file.instrumentZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
                 file.sampleSourceCollection());
    }
  }

  /**
   Locate the instrument zones that apply to the given key/velocity values.

   @param key the MIDI key number
   @param velocity the MIDI velocity value
   @returns vector of matching zones
   */
  CollectionType::Matches filter(int key, int velocity) const { return zones_.filter(key, velocity); }
};

} // namespace SF2::Render
