// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
#include "SFModulator.hpp"
#include "SFGenerator.hpp"
#include "SFTransform.hpp"

namespace SF2 {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 */
struct SFMod {
    static constexpr size_t size = 10;

    SFModulator sfModSrcOper;
    SFGenerator sfModDestOper;
    int16_t modAmount;
    SFModulator sfModAmtSrcOper;
    SFTransform sfModTransOper;

    SFMod(BinaryStream& is) { is.copyInto(this); }
    
    void dump(const std::string& indent, int index) const
    {
        std::cout << indent << index
        << ": src: " << sfModSrcOper
        << " dest: " << sfModDestOper.name()
        << " amount: " << modAmount
        << " op: " << sfModAmtSrcOper
        << " xform: " << sfModTransOper.bits_
        << std::endl;
    }
};

}
