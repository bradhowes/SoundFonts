// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFSample.hpp"

namespace SF2 {

/**
 Collection of SFSample entities that represents all of the samples in an SF2 file.
 */
struct Samples : ChunkItems<SFSample>
{
    using Super = ChunkItems<SFSample>;

    Samples() : Super() {}
    
    Samples(Chunk const& chunk) : Super(chunk) {}
};

}
