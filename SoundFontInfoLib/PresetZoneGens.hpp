// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFGenList.hpp"

namespace SF2 {

/**
 Collection of SFGenList entities that represents all of the gen definitions for the zones in an SF2 file.
 */
struct PresetZoneGens : ChunkItems<SFGenList>
{
    using Super = ChunkItems<SFGenList>;

    PresetZoneGens() : Super() {}
    
    PresetZoneGens(Chunk const& chunk) : Super(chunk) {}
};

}
