// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <string>

#include "ChunkItems.hpp"
#include "SFInst.hpp"

namespace SF2 {

struct Instrument : ChunkItems<SFInst>
{
    using Super = ChunkItems<SFInst>;

    Instrument(Chunk const& chunk) : Super(chunk) {}
};

}
