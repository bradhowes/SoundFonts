// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFGenList.hpp"

namespace SF2 {

struct PresetZoneGen : ChunkItems<SFGenList>
{
    using Super = ChunkItems<SFGenList>;

    PresetZoneGen(Chunk const& chunk) : Super(chunk) {}
};

}
