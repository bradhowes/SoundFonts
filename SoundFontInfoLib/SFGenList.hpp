// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFGenList_hpp
#define SFGenList_hpp

#include <string>

#include "SFGenerator.hpp"
#include "SFGenTypeAmount.hpp"

namespace SF2 {

struct sfGenList {
    SFGenerator sfGenOper;
    SFGenTypeAmount genAmount;

    const char* load(const char* pos, size_t available);
    void dump(const std::string& indent, int index) const;
};

}

#endif /* SFGenList_hpp */
