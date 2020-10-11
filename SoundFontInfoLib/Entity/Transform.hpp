// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <cstdlib>
#include <iostream>

namespace SF2 {
namespace Entity {

class Transform {
public:

    enum struct Kind {
        linear = 0,
        absolute = 2
    };

    Transform() : bits_{0} {}

    Kind kind() const { return bits_ == 0 ? Kind::linear : Kind::absolute; }

    float transform(float value) const;

    friend std::ostream& operator<<(std::ostream& os, Transform const& value) {
        return os << (value.kind() == Kind::linear ? "linear" : "absolute");
    }

private:
    const uint16_t bits_;
};

inline float Transform::transform(float value) const
{
    switch (kind()) {
        case Kind::linear: return value;
        case Kind::absolute: return abs(value);
        default: throw "unexpected tranform kind";
    }
}

}
}
