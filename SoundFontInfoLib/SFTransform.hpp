// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2 {

struct SFTransform {
    SFTransform() : bits_(0) {}
    SFTransform(uint16_t bits) : bits_{bits} {}
    const uint16_t bits_;
};

}
