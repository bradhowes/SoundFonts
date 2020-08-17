// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2 {

struct SFGenTypeAmount {
    SFGenTypeAmount() : raw_{} {}
    SFGenTypeAmount(uint16_t raw) : raw_{raw} {}

    uint16_t index() const { return raw_.wAmount; }
    int16_t amount() const { return raw_.shAmount; }
    uint16_t low() const { return raw_.ranges[0]; }
    uint16_t high() const { return raw_.ranges[1]; }
    uint8_t const* const ranges() const { return raw_.ranges; }

    union {
        uint16_t wAmount;
        int16_t shAmount;
        uint8_t ranges[2];
    } raw_;
};

}
