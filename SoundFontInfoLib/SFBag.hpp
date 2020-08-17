// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"

namespace SF2 {

/**
 Memory layout of a 'ibag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4.
 */
struct SFBag {
    constexpr static size_t size = 4;

    uint16_t wGenNdx;
    uint16_t wModNdx;

    SFBag(BinaryStream& is) { is.copyInto(this); }

    void dump(const std::string& indent, int index) const
    {
        auto next = this + 1;
        std::cout << indent << index
        << ": genIndex: " << wGenNdx
        << " count: " << (next->wGenNdx - wGenNdx)
        << " modIndex: " << wModNdx << " count: " << (next->wModNdx - wModNdx)
        << std::endl;
    }
};

}
