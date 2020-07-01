// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFModulator_hpp
#define SFModulator_hpp

#include <cstdlib>
#include <iostream>

namespace SF2 {

struct SFModulator {
    static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switch" };

    SFModulator() : bits_{0} {}
    SFModulator(uint16_t bits) : bits_{bits} {}

    short type() const { return bits_ >> 10; }
    bool polarity() const { return bits_ & (1 << 9); }
    bool direction() const { return bits_ & (1 << 8); }
    bool continuousController() const { return bits_ & (1 << 7); }
    short index() const { return bits_ & 0x7F; }

    char const* typeName() const { return typeNames[type()]; }

    friend std::ostream& operator<<(std::ostream& os, SFModulator const& mod)
    {
        return os << "[type: " << mod.typeName()
        << " P: " << mod.polarity()
        << " D: " << mod.direction()
        << " CC: " << mod.continuousController()
        << " index: " << mod.index()
        << "]";
    }

private:
    const uint16_t bits_;
};

}

#endif /* SFModulator_hpp */
