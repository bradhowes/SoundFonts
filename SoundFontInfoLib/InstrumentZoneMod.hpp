// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef InstrumentZoneMod_hpp
#define InstrumentZoneMod_hpp

#include <cstdlib>
#include <iostream>
#include <string>

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

struct InstrumentZoneMod : ChunkItems<sfModList, 4>
{
    using Super = ChunkItems<sfModList, 4>;

    InstrumentZoneMod(const Chunk& chunk) : Super(chunk) {}
};

}

#endif /* InstrumentZoneMod_hpp */
