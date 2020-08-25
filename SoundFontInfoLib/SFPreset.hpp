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

    explicit SFPreset(BinaryStream& is)
    {
        // Account for the extra padding by reading twice.
        is.copyInto(&achPresetName, 26);
        is.copyInto(&dwLibrary, 12);
        trim_property(achPresetName);
    }

    auto name() const -> auto{ return achPresetName; }
    auto preset() const -> auto { return wPreset; }
    auto bank() const -> auto { return wBank; }
    auto zoneIndex() const -> auto { return wPresetBagNdx; }

    auto next() const -> auto { return *(this + 1); }
    auto zoneCount() const -> auto { return next().zoneIndex() - zoneIndex(); }

    void dump(const std::string& indent, int index) const
    {
        std::cout << indent << index << ": '" << name() << "' preset: " << preset()
        << " bank: " << bank()
        << " zoneIndex: " << zoneIndex() << " count: " << zoneCount() << std::endl;
    }

private:
    char achPresetName[20];
    uint16_t wPreset;
    uint16_t wBank;
    uint16_t wPresetBagNdx;
    uint32_t dwLibrary;
    uint32_t dwGenre;
    uint32_t dwMorphology;
};

}
