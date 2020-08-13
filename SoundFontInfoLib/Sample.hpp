// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "ChunkItems.hpp"
#include "SFSample.hpp"

namespace SF2 {

struct Sample : ChunkItems<SFSample>
{
    using Super = ChunkItems<SFSample>;

    Sample(Chunk const& chunk) : Super(chunk) {}
};

}
