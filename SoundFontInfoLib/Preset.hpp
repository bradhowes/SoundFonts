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
    constexpr static size_t size = 38;

    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;

    void dump(const std::string& indent, int index) const;
    char const* load(char const* pos, size_t available);
};

struct Preset : ChunkItems<sfPreset>
{
    using Super = ChunkItems<sfPreset>;

    Preset(Chunk const& chunk) : Super(chunk) {}
};

}

#endif /* Preset_hpp */
