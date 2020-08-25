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

    auto kind() const -> auto { return bits_ == 0 ? kTransformKindLinear : kTransformKindAbsolute; }

    auto transform(float value) const -> auto {
        switch (kind()) {
            case kTransformKindLinear: return value;
            case kTransformKindAbsolute: return abs(value);
            default: throw "unexpected tranform kind";
        }
    }

    friend std::ostream& operator<<(std::ostream& os, SFTransform const& value)
    {
        return os << (value.kind() == kTransformKindLinear ? "Linear" : "Absolute");
    }

private:
    const uint16_t bits_;
};

}
