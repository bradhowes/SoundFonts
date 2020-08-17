// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <cstdlib>

namespace SF2 {

class SFTransform {
public:

    enum TransformKind {
        kTransformKindLinear = 0,
        kTransformKindAbsolute = 2
    };

    SFTransform() : bits_{0} {}

    TransformKind kind() const { return bits_ == 0 ? kTransformKindLinear : kTransformKindAbsolute; }

    friend std::ostream& operator<<(std::ostream& os, SFTransform const& value)
    {
        return os << (value.kind() == kTransformKindLinear ? "Linear" : "Absolute");
    }

    float transform(float value) const {
        switch (kind()) {
            case kTransformKindLinear: return value;
            case kTransformKindAbsolute: return abs(value);
            default: throw "unexpected tranform kind";
        }
    }

private:
    const uint16_t bits_;
};

}
