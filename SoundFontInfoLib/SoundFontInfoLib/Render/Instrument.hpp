// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "IO/File.hpp"

#include "Render/InstrumentZone.hpp"
#include "Render/WithZones.hpp"

namespace SF2::Render {

/**
 Representation of an `instrument` in an SF2 file. An instrument is made up of one or more zones, where a zone is
 defined as a collection of generators and modulators that apply for a particular MIDI key value and/or velocity.
 All instrument zone generators except the very first must end with generator index #53 `sampleID` which indicates
 which `SampleBuffer` to use to render audio. If the first zone of an instrument does not end with a `sampleID`
 generator, then it is considered to be the one and only `global` zone, with its generators/modulators applied to all
 other zones unless a zone has its own definition.
 */
class Instrument : public WithZones<InstrumentZone, Entity::Instrument>
{
public:
    using InstrumentZoneCollection = WithZoneCollection;

    /**
     Construct new Instrument from SF2 entities

     @param file the SF2 file that was loaded
     @param config the SF2 file entity that defines the instrument
     */
    Instrument(const IO::File& file, const Entity::Instrument& config) :
    WithZones<InstrumentZone, Entity::Instrument>(config.zoneCount(), config) {
        for (const Entity::Bag& bag : file.instrumentZones().slice(config.firstZoneIndex(), config.zoneCount())) {
            zones_.add(file, bag);
        }
    }

    /**
     Locate the instrument zones that apply to the given key/velocity values.

     @param key the MIDI key number
     @param velocity the MIDI velocity value
     @returns vector of matching zones
     */
    InstrumentZoneCollection::Matches filter(int key, int velocity) const { return zones_.filter(key, velocity); }
};

} // namespace SF2::Render
