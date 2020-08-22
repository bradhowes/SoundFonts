// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFBag.hpp"

namespace SF2 {

/**
 Collection of SFInstBag instances representing all of the instrument/preset zones in an SF2 file.
 */
struct Zones : ChunkItems<SFBag>
{
    using Super = ChunkItems<SFBag>;

    Zones() : Super() {}
    
    Zones(Chunk const& chunk) : Super(chunk) {}
};

}
