// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFPreset.hpp"

namespace SF2 {

/**
 Collection of SFPreset entities that represents all of the presets in an SF2 file.
 */
struct Presets : ChunkItems<SFPreset>
{
    using Super = ChunkItems<SFPreset>;

    Presets() : Super() {}
    
    Presets(Chunk const& chunk) : Super(chunk) {}
};

}
