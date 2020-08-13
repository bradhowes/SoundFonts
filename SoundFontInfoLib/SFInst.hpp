// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "StringUtils.hpp"

namespace SF2 {

/**
 Memory layout of a 'inst' entry. The size of this is defined to be 22 bytes.
 */
struct SFInst {
    constexpr static size_t size = 22;

    char achInstName[20];
    uint16_t wInstBagNdx;

    SFInst(BinaryStream& is)
    {
        is.copyInto(this);
        trim_property(achInstName);
    }

    void dump(std::string const& indent, int index) const
    {
        auto next = this + 1;
        std::string name(achInstName, 19);
        trim(name);
        std::cout << indent << index << ": '" << name
        << "' ibagIndex: " << wInstBagNdx << " count: " << (next->wInstBagNdx - wInstBagNdx) << std::endl;
    }
};

}
