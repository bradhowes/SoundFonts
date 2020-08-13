// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <string>

#include "ChunkItems.hpp"
#include "SFInst.hpp"

namespace SF2 {

/**
 Collection of SFInst representing all of the instruments defined in an SF2 file.
 */
struct Instruments : ChunkItems<SFInst>
{
    using Super = ChunkItems<SFInst>;

    Instruments() : Super() {}

    Instruments(Chunk const& chunk) : Super(chunk) {}
};

}
