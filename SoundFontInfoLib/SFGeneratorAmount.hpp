// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2 {

struct SFGeneratorAmount {
    SFGeneratorAmount() : raw_{} {}
    explicit SFGeneratorAmount(uint16_t raw) : raw_{raw} {}

    auto index() const -> auto { return raw_.wAmount; }
    auto amount() const -> auto { return raw_.shAmount; }
    auto low() const -> auto { return raw_.ranges[0]; }
    auto high() const -> auto { return raw_.ranges[1]; }
    auto ranges() const -> auto { return raw_.ranges; }

    union {
        uint16_t wAmount;
        int16_t shAmount;
        uint8_t ranges[2];
    } raw_;
};

}
