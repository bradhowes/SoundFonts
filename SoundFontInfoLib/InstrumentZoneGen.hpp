// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef InstrumentZoneGen_hpp
#define InstrumentZoneGen_hpp

#include "ChunkItems.hpp"
#include "SFGenList.hpp"

namespace SF2 {

struct InstrumentZoneGen : ChunkItems<sfGenList>
{
    using Super = ChunkItems<sfGenList>;

    InstrumentZoneGen(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* InstrumentZoneGen_hpp */
