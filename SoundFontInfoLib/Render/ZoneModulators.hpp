// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../Entity/Modulator/Modulator.hpp"
#include "../IO/ChunkItems.hpp"

namespace SF2 {
namespace Render {

/**
 Collection of SFModList entities that represent mod definitions for the instrument zones of an SF2 file.
 */
struct ZoneModulators : IO::ChunkItems<SFModulator>
{
    using Super = IO::ChunkItems<SFModulator>;

    ZoneModulators() : Super() {}
    
    ZoneModulators(const IO::Chunk& chunk) : Super(chunk) {}
};

}
}
