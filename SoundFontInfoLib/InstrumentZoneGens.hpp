// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFGen.hpp"

namespace SF2 {

/**
 Collection of SFGenList entities that represent generator definitions for the instrument zones of an SF2 file. Any
 given instrument zone contains in index into this collection. The number of items that belong to a given instrument
 zone is defined by the span between the index of the zone and the index of the next zone.
 */
struct InstrumentZoneGens : ChunkItems<SFGen>
{
    using Super = ChunkItems<SFGen>;

    InstrumentZoneGens() : Super() {}
    
    InstrumentZoneGens(Chunk const& chunk) : Super(chunk) {}
};

}
