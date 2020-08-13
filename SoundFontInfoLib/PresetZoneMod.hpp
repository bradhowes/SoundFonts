// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

struct PresetZoneMod : ChunkItems<SFModList>
{
    using Super = ChunkItems<SFModList>;

    PresetZoneMod(Chunk const& chunk) : Super(chunk) {}
};

}
