// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef InstrumentZoneMod_hpp
#define InstrumentZoneMod_hpp

#include <cstdlib>
#include <iostream>
#include <string>

#include "ChunkItems.hpp"
#include "SFModList.hpp"

namespace SF2 {

struct InstrumentZoneMod : ChunkItems<sfModList>
{
    using Super = ChunkItems<sfModList>;

    InstrumentZoneMod(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* InstrumentZoneMod_hpp */
