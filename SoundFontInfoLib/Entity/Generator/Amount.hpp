// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Holds the amount to apply to a generator. Note that this is an immutable value.
 */
class Amount {
public:
    static constexpr size_t size = 2;

    /**
     Constructor with specific value

     @param raw the value to hold
     */
    explicit Amount(uint16_t raw) : raw_{raw} { assert(sizeof(*this) == size); }

    /**
     Default constructor. Sets held value to 0.
     */
    Amount() : Amount(0) {}

    /// @returns unsigned integer value
    uint16_t index() const { return raw_.wAmount; }

    /// @returns signed integer value
    int16_t amount() const { return raw_.shAmount; }

    /// @returns low value of a range (0-255)
    int low() const { return int(raw_.ranges[0]); }

    /// @returns high value of a range (0-255)
    int high() const { return int(raw_.ranges[1]); }

    void setIndex(uint16_t value) { raw_.wAmount = value; }
    void setAmount(int16_t value) { raw_.shAmount = value; }

    void refine(uint16_t value) { raw_.wAmount += value; }
    void refine(int16_t value) { raw_.shAmount += value; }

private:

    union {
        uint16_t wAmount;
        int16_t shAmount;
        uint8_t ranges[2];
    } raw_;
};

}
}
}
