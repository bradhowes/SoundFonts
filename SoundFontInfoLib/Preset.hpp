// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef Preset_hpp
#define Preset_hpp

#include <string>

#include "ChunkItems.hpp"

namespace SF2 {

/**
 Memory layout of 'phdr' entry in sound font. The size of this is defined to be 38 bytes, but due
 to alignment/padding the struct below is 40 bytes.
 */
struct sfPreset {
    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;

    void dump(const std::string& indent, int index) const;
    const char* load(const char* pos, size_t available);
};

struct Preset : ChunkItems<sfPreset, 38>
{
    using Super = ChunkItems<sfPreset, 38>;

    Preset(const Chunk& chunk) : Super(chunk) {}
};

}

#endif /* Preset_hpp */
