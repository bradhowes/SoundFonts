// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFGenList_hpp
#define SFGenList_hpp

#include <string>

#include "SFGenerator.hpp"
#include "SFGenTypeAmount.hpp"

namespace SF2 {

/**
 Memory layout of a 'pgen'/'igen' entry. The size of this is defined to be 4.
 */
struct sfGenList {
    static constexpr size_t size = 4;

    SFGenerator sfGenOper;
    SFGenTypeAmount genAmount;

    char const* load(char const* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

}

#endif /* SFGenList_hpp */
