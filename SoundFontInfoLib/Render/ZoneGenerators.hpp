// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Generator.hpp"
#include "IO/ChunkItems.hpp"

namespace SF2 {
namespace Render {

/**
 Collection of SFGenList entities that represent generator definitions for the instrument zones of an SF2 file. Any
 given instrument zone contains in index into this collection. The number of items that belong to a given instrument
 zone is defined by the span between the index of the zone and the index of the next zone.
 */
struct ZoneGenerators : IO::ChunkItems<SFGenerator>
{
    using Super = IO::ChunkItems<SFGenerator>;

    ZoneGenerators() : Super() {}
    
    ZoneGenerators(const IO::Chunk& chunk) : Super(chunk) {}
};

} // namespace Render
} // namespace SF2
