// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFTransform_hpp
#define SFTransform_hpp

#include <cstdlib>

namespace SF2 {

struct SFTransform {
    SFTransform() : bits_(0) {}
    SFTransform(uint16_t bits) : bits_{bits} {}
    const uint16_t bits_;
};

}

#endif /* SFTransform_hpp */
