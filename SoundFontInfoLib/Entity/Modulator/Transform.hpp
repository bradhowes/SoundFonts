// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <cstdlib>
#include <iostream>

namespace SF2 {
namespace Entity {
namespace Modulator {

/**
 Modulator value transform. The spec defines two types:

 - linear: value is used as-is
 - absolute: negative values are made positive before being used

 Currently, the 10 default modulators only use `linear`.
 */
class Transform {
public:

    enum struct Kind {
        linear = 0,
        absolute = 2
    };

    /**
     Constructor

     @param bits the value that determines the type of transform to apply
     */
    explicit Transform(uint16_t bits) : bits_{bits} {}

    /**
     Default constructor.
     */
    Transform() : Transform(0) {}

    /// @returns the kind of transform to apply
    Kind kind() const { return bits_ == 0 ? Kind::linear : Kind::absolute; }

    /**
     Transform a value.

     @param value the value to transform
     @returns transformed value
     */
    template <typename T>
    T transform(T value) const {
        switch (kind()) {
            case Kind::linear: return value;
            case Kind::absolute: return std::abs(value);
            default: throw "unexpected tranform kind";
        }
    }

    friend std::ostream& operator<<(std::ostream& os, const Transform& value) {
        return os << (value.kind() == Kind::linear ? "linear" : "absolute");
    }

private:
    const uint16_t bits_;
};

} // end namespace Modulator
} // end namespace Entity
} // end namespace SF2
