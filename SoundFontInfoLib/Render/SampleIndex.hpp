// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

namespace SF2 {
namespace Render {

struct SampleIndex {

    explicit SampleIndex(uint32_t value)
    : value_(uint64_t(value) << 32)
    {}

    explicit SampleIndex(double value)
    : value_(fromDouble(value))
    {}

    uint32_t whole() const { return value_ >> 32; }
    uint32_t partial() const { return value_ & partialMask; }

    double value() const { return whole() + double(partial()) / double(std::numeric_limits<uint32_t>::max()); }

    SampleIndex& operator +=(SampleIndex rhs) {
        value_ += rhs.value_;
        return *this;
    }

    SampleIndex& operator -=(SampleIndex rhs) {
        value_ -= rhs.value_;
        return *this;
    }

    SampleIndex& operator ++() {
        value_ += one;
        return *this;
    }

    SampleIndex& operator --() {
        value_ -= one;
        return *this;
    }

private:
    static constexpr uint64_t partialMask = 0x00000000FFFFFFFFul;

    static constexpr uint64_t one = uint64_t(1) << 32;

    static uint64_t fromDouble(double value) {
        uint64_t whole = uint32_t(value);
        uint64_t partial = (value - whole) * double(std::numeric_limits<uint32_t>::max());
        return whole << 32 | partial;
    }

    uint64_t value_;
};

}
}
