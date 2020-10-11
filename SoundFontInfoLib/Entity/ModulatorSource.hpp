// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdlib>
#include <iostream>
#include <string>

namespace SF2 {
namespace Entity {

class ModulatorSource {
public:
    ModulatorSource() : bits_{0} {}
    explicit ModulatorSource(uint16_t bits) : bits_{bits} {}

    uint16_t type() const { return bits_ >> 10; }
    uint16_t polarity() const { return bits_ & (1 << 9); }
    uint16_t direction() const { return bits_ & (1 << 8); }

    bool isUnipolar() const { return polarity() == 0; }
    bool isBipolar() const { return !isUnipolar(); }

    bool isMinToMax() const { return direction() == 0; }
    bool isMaxToMin() const { return !isMinToMax(); }

    bool isContinuousController() const { return (bits_ & (1 << 7)) ? true : false; }

    uint16_t index() const { return bits_ & 0x7F; }
    std::string typeName() const { return std::string(typeNames[type()]); }

    friend std::ostream& operator<<(std::ostream& os, ModulatorSource const& mod);

private:
    static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switch" };

    uint16_t bits_;
};

inline std::ostream& operator<<(std::ostream& os, ModulatorSource const& mod)
{
    return os << "[type: " << mod.typeName()
    << " P: " << mod.polarity()
    << " D: " << mod.direction()
    << " CC: " << mod.isContinuousController()
    << " index: " << mod.index()
    << "]";
}

}
}
