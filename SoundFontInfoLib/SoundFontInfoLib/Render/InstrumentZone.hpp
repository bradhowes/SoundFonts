// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"

#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

class VoiceState;

/**
 A specialization of a Zone for an Instrument. Instrument zones have a sample buffer.
 */
class InstrumentZone : public Zone {
public:

    /**
     Construct new zone from entity in file.

     @param file the file to work with
     @param bag the zone definition
     */
    InstrumentZone(const IO::File& file, const Entity::Bag& bag) :
    Zone(file.instrumentZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
         file.instrumentZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
         Entity::Generator::Index::sampleID),
    sampleBuffer_{isGlobal() ? nullptr : &file.sampleBuffer(resourceLink())}
    {}

    /**
     Apply the zone generator values to the given voice state.

     @param state the state to update
     */
    void apply(Voice::State& state) const { Zone::apply(state); }

    /// @returns the sample buffer registered to this zone, or nullptr if this is a global zone.
    const Render::Sample::CanonicalBuffer* sampleBuffer() const { return sampleBuffer_; }

private:
    const Render::Sample::CanonicalBuffer* sampleBuffer_;
};

} // namespace Render
} // namespace SF2