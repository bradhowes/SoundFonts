// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFPresetBag.hpp"

namespace SF2 {

struct PresetZone : ChunkItems<SFPresetBag>
{
    using Super = ChunkItems<SFPresetBag>;

    PresetZone(Chunk const& chunk) : Super(chunk) {}
};

}
