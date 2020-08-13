// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFInstBag.hpp"

namespace SF2 {

struct InstrumentZone : ChunkItems<SFInstBag>
{
    using Super = ChunkItems<SFInstBag>;

    InstrumentZone(Chunk const& chunk) : Super(chunk) {}
};

}
