// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "Chunk.hpp"
#include "Pos.hpp"
#include "StringUtils.hpp"

namespace SF2 {

/**
 Memory layout of 'phdr' entry in sound font. The size of this is defined to be 38 bytes, but due
 to alignment/padding the struct below is 40 bytes.
 */
class SFPreset {
public:
    constexpr static size_t size = 38;

    explicit SFPreset(Pos& pos)
    {
        // Account for the extra padding by reading twice.
        pos = pos.readInto(&achPresetName, 26);
        pos = pos.readInto(&dwLibrary, 12);
        trim_property(achPresetName);
    }
    
    char const* name() const { return achPresetName; }
    uint16_t preset() const { return wPreset; }
    uint16_t bank() const { return wBank; }

    uint16_t zoneIndex() const { return wPresetBagNdx; }
    uint16_t zoneCount() const { return (this + 1)->zoneIndex() - zoneIndex(); }

    void dump(const std::string& indent, int index) const;

private:
    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    // *** PADDIING ***
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;
};

inline void SFPreset::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << name() << "' preset: " << preset()
    << " bank: " << bank()
    << " zoneIndex: " << zoneIndex() << " count: " << zoneCount() << std::endl;
}

}
