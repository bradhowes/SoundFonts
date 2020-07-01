// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef Sample_hpp
#define Sample_hpp

#include <string>

#include "ChunkItems.hpp"

namespace SF2 {

/**
 Memory layout of a 'shdr' entry. The size of this is defined to be 46 bytes, but due
 to alignment/padding the struct below is 48 bytes.
 */
struct sfSample {
    char achSampleName[20];
    uint32_t dwStart;
    uint32_t dwEnd;
    uint32_t dwStartLoop;
    uint32_t dwEndLoop;
    uint32_t dwSampleRate;
    uint8_t originalKey;
    int8_t correction;
    uint16_t sampleLink;
    uint16_t sampleType;

    char const* load(char const* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

struct Sample : ChunkItems<sfSample, 46>
{
    using Super = ChunkItems<sfSample, 46>;

    Sample(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* Sample_hpp */
