// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>
#include <iostream>

namespace SF2 {

struct SFModulatorSource {
    static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switch" };

    constexpr SFModulatorSource() : bits_{0} {}
    constexpr SFModulatorSource(uint16_t bits) : bits_{bits} {}

    short type() const { return bits_ >> 10; }

    short polarity() const { return bits_ & (1 << 9); }
    bool isUnipolar() const { return polarity() == 0; }
    bool isBipolar() const { return !isUnipolar(); }

    bool direction() const { return bits_ & (1 << 8); }
    bool isMinToMax() const { return direction() == 0; }
    bool isMaxToMin() const { return !isMinToMax(); }

    bool isContinuousController() const { return (bits_ & (1 << 7)) ? true : false; }

    short index() const { return bits_ & 0x7F; }
    char const* typeName() const { return typeNames[type()]; }

    friend std::ostream& operator<<(std::ostream& os, SFModulatorSource const& mod)
    {
        return os << "[type: " << mod.typeName()
        << " P: " << mod.polarity()
        << " D: " << mod.direction()
        << " CC: " << mod.isContinuousController()
        << " index: " << mod.index()
        << "]";
    }

private:
    uint16_t bits_;
};

}
