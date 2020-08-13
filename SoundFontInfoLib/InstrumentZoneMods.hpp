// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFMod.hpp"

namespace SF2 {

/**
 Collection of SFModList entities that represent mod definitions for the instrument zones of an SF2 file.
 */
struct InstrumentZoneMods : ChunkItems<SFMod>
{
    using Super = ChunkItems<SFMod>;

    InstrumentZoneMods() : Super() {}
    
    InstrumentZoneMods(Chunk const& chunk) : Super(chunk) {}
};

}
