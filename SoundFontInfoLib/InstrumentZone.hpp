// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef InstrumentZone_hpp
#define InstrumentZone_hpp

#include <string>

#include "ChunkItems.hpp"

namespace SF2 {

/**
 Memory layout of a 'ibag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4.
 */
struct sfInstBag {
    constexpr static size_t size = 4;

    uint16_t wInstGenNdx;
    uint16_t wInstModNdx;

    char const* load(char const* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

struct InstrumentZone : ChunkItems<sfInstBag>
{
    using Super = ChunkItems<sfInstBag>;

    InstrumentZone(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* InstrumentZone_hpp */
