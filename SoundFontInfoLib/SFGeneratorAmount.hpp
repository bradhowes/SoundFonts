// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2 {

class SFGeneratorAmount {
public:
    SFGeneratorAmount() : raw_{} {}

    explicit SFGeneratorAmount(uint16_t raw) : raw_{raw} {}

    uint16_t index() const { return raw_; }
    int16_t amount() const { return static_cast<int16_t>(raw_); }

    int low() const { return int(raw_ & 0x7FFF) & 0xFF; }
    int high() const { return int(raw_ & 0x7FFF) >> 8; }

    void refine(uint16_t value) { raw_ = index() + value; }
    void refine(int16_t value) { raw_ = amount() + value; }

private:
    uint16_t raw_;
};

}
