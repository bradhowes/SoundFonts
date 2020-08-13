// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFInstBag.hpp"

namespace SF2 {

/**
 Collection of SFInstBag instances representing all of the instrument zones in an SF2 file.
 */
struct InstrumentZones : ChunkItems<SFInstBag>
{
    using Super = ChunkItems<SFInstBag>;

    InstrumentZones() : Super() {}
    
    InstrumentZones(Chunk const& chunk) : Super(chunk) {}
};

}
