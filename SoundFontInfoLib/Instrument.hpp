// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef Instrument_hpp
#define Instrument_hpp

#include <string>

#include "ChunkItems.hpp"

namespace SF2 {

/**
 Memory layout of a 'inst' entry. The size of this is defined to be 22 bytes.
 */
struct sfInst {
    char achInstName[20];
    uint16_t wInstBagNdx;

    const char* load(const char* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

struct Instrument : ChunkItems<sfInst, 22>
{
    using Super = ChunkItems<sfInst, 22>;

    Instrument(const Chunk& chunk) : Super(chunk) {}
};

}

#endif /* Instrument_hpp */
