// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <cstdlib>

namespace SF2 {

class SFTransform {
public:

    enum struct Kind {
        linear = 0,
        absolute = 2
    };

    SFTransform() : bits_{0} {}

    Kind kind() const { return bits_ == 0 ? Kind::linear : Kind::absolute; }

    float transform(float value) const;

    friend std::ostream& operator<<(std::ostream& os, SFTransform const& value) {
        return os << (value.kind() == Kind::linear ? "linear" : "absolute");
    }

private:
    const uint16_t bits_;
};

inline float SFTransform::transform(float value) const
{
    switch (kind()) {
        case Kind::linear: return value;
        case Kind::absolute: return abs(value);
        default: throw "unexpected tranform kind";
    }
}

}
