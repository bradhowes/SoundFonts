// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "StringUtils.hpp"

namespace SF2 {

/**
 Memory layout of 'phdr' entry in sound font. The size of this is defined to be 38 bytes, but due
 to alignment/padding the struct below is 40 bytes.
 */
struct SFPreset {
    constexpr static size_t size = 38;

    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;

    SFPreset(BinaryStream& is)
    {
        is.copyInto(&achPresetName, 26);
        is.copyInto(&dwLibrary, 12);
        trim_property(achPresetName);
    }

    void dump(const std::string& indent, int index) const
    {
        auto next = this + 1;
        std::cout << indent << index << ": '" << achPresetName << "' preset: " << wPreset
        << " bank: " << wBank
        << " pbagIndex: " << wPresetBagNdx
        << " count: " << (next->wPresetBagNdx - wPresetBagNdx) << std::endl;
    }
};

}
