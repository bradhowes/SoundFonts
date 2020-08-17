// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFModulator.hpp"

namespace SF2 {

/**
 Collection of SFModList entities that represent mod definitions for the instrument zones of an SF2 file.
 */
struct ZoneModulators : ChunkItems<SFModulator>
{
    using Super = ChunkItems<SFModulator>;

    ZoneModulators() : Super() {}
    
    ZoneModulators(Chunk const& chunk) : Super(chunk) {}
};

}
