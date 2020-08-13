// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "StringUtils.hpp"

namespace SF2 {

/**
 Memory layout of a 'pbag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4.
 */
struct SFPresetBag {
    constexpr static size_t size = 4;

    uint16_t wGenNdx;
    uint16_t wModNdx;

    SFPresetBag(BinaryStream& is) { is.copyInto(this); }

    void dump(const std::string& indent, int index) const
    {
        auto next = this + 1;
        std::cout << indent << index
        << ": genIndex: " << wGenNdx
        << " count: " << (next->wGenNdx - wGenNdx)
        << " modIndex: " << wModNdx
        << " count: " << (next->wModNdx - wModNdx)
        << std::endl;
    }
};

}
