// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFPresetBag.hpp"

namespace SF2 {

/**
 Collection of SFPresetBag entities that represents all of the preset zones in an SF2 file.
 */
struct PresetZones : ChunkItems<SFPresetBag>
{
    using Super = ChunkItems<SFPresetBag>;

    PresetZones() : Super() {}
    
    PresetZones(Chunk const& chunk) : Super(chunk) {}
};

}
