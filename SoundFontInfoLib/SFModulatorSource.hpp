// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>
#include <iostream>

namespace SF2 {

struct SFModulatorSource {
    static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switch" };

    constexpr SFModulatorSource() : bits_{0} {}
    constexpr explicit SFModulatorSource(uint16_t bits) : bits_{bits} {}

    auto type() const -> auto { return bits_ >> 10; }
    auto polarity() const -> auto { return bits_ & (1 << 9); }
    auto isUnipolar() const -> auto { return polarity() == 0; }
    auto isBipolar() const -> auto { return !isUnipolar(); }

    auto direction() const -> auto { return bits_ & (1 << 8); }
    auto isMinToMax() const -> auto { return direction() == 0; }
    auto isMaxToMin() const -> auto { return !isMinToMax(); }

    auto isContinuousController() const -> auto { return (bits_ & (1 << 7)) ? true : false; }

    auto index() const -> auto { return bits_ & 0x7F; }
    auto typeName() const -> auto { return typeNames[type()]; }

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
