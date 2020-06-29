// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef InstrumentZoneGen_hpp
#define InstrumentZoneGen_hpp

#include "ChunkItems.hpp"
#include "SFGenList.hpp"

namespace SF2 {

struct InstrumentZoneGen : ChunkItems<sfGenList, 4>
{
    using Super = ChunkItems<sfGenList, 4>;

    InstrumentZoneGen(const Chunk& chunk) : Super(chunk) {}
};

}

#endif /* InstrumentZoneGen_hpp */
