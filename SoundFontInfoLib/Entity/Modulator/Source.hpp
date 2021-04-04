// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cstdlib>
#include <iostream>
#include <string>

namespace SF2 {
namespace Entity {
namespace Modulator {

/**
 The source of a modulator.
 */
class Source {
public:
    enum struct GeneralIndex : uint16_t {
        none = 0,
        noteOnVelocity = 2,
        noteOnKeyValue = 3,
        polyPressure = 10,
        channelPressure = 13,
        pitchWheel = 14,
        pitchWheelSensitivity = 16,
        link = 127
    };

    enum struct ContinuityType : uint16_t {
        linear = 0,
        concave,
        convex,
        switched
    };

    explicit Source(uint16_t bits) : bits_{bits} {}

    Source() : Source(0) {}

    bool isValid() const {
        if (rawType() >= 4) return false;
        auto idx = rawIndex();
        if (isContinuousController()) {
            return !(idx == 0 || idx == 6 || (idx >=32 && idx <= 63) || idx == 98 || idx == 101 ||
                     (idx >= 120 && idx <= 127));
        }
        else {
            return idx == 0 || idx == 2 || idx == 3 || idx == 10 || idx == 13 || idx == 14 || idx == 16 || idx == 127;
        }
    }

    bool isContinuousController() const { return (bits_ & (1 << 7)) ? true : false; }
    bool isUnipolar() const { return polarity() == 0; }
    bool isBipolar() const { return !isUnipolar(); }
    bool isMinToMax() const { return direction() == 0; }
    bool isMaxToMin() const { return !isMinToMax(); }

    GeneralIndex generalIndex() const {
        assert(isValid() && !isContinuousController());
        return GeneralIndex(rawIndex());
    }

    int continuousIndex() const {
        assert(isValid() && isContinuousController());
        return rawIndex();
    }

    ContinuityType type() {
        assert(isValid());
        return ContinuityType(rawType());
    }

    std::string typeName() const { return isValid() ? std::string(typeNames[rawType()]) : "N/A"; }

    friend std::ostream& operator<<(std::ostream& os, const Source& mod);

private:
    static constexpr char const* typeNames[] = { "linear", "concave", "convex", "switched" };

    uint16_t rawIndex() const { return bits_ & 0x7F; }
    uint16_t rawType() const { return bits_ >> 10; }
    uint16_t polarity() const { return bits_ & (1 << 9); }
    uint16_t direction() const { return bits_ & (1 << 8); }

    uint16_t bits_;
};

inline std::ostream& operator<<(std::ostream& os, const Source& mod)
{
    return os << "[type: " << mod.typeName()
    << " P: " << mod.polarity()
    << " D: " << mod.direction()
    << " CC: " << mod.isContinuousController()
    << " index: " << mod.rawIndex()
    << "]";
}

}
}
}
