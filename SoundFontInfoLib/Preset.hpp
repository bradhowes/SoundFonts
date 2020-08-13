// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFPreset.hpp"

namespace SF2 {

struct Preset : ChunkItems<SFPreset>
{
    using Super = ChunkItems<SFPreset>;

    Preset(Chunk const& chunk) : Super(chunk) {}
};

}
