// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFModList_hpp
#define SFModList_hpp

#include <string>

#include "SFModulator.hpp"
#include "SFGenerator.hpp"
#include "SFTransform.hpp"

namespace SF2 {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 */
struct sfModList {
    static constexpr size_t size = 10;

    SFModulator sfModSrcOper;
    SFGenerator sfModDestOper;
    int16_t modAmount;
    SFModulator sfModAmtSrcOper;
    SFTransform sfModTransOper;

    const char* load(const char* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

}

#endif /* SFModList_hpp */
