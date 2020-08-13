// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

/**
 Collection of SFModList entities that represent mod definitions for the instrument zones of an SF2 file.
 */
struct InstrumentZoneMods : ChunkItems<SFModList>
{
    using Super = ChunkItems<SFModList>;

    InstrumentZoneMods() : Super() {}
    
    InstrumentZoneMods(Chunk const& chunk) : Super(chunk) {}
};

}
