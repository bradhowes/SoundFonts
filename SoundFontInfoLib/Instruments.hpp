// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <string>

#include "ChunkItems.hpp"
#include "SFInstrument.hpp"

namespace SF2 {

/**
 Collection of SFInst representing all of the instruments defined in an SF2 file.
 */
struct Instruments : ChunkItems<SFInstrument>
{
    using Super = ChunkItems<SFInstrument>;

    Instruments() : Super() {}

    explicit Instruments(Chunk const& chunk) : Super(chunk) {}
};

}
