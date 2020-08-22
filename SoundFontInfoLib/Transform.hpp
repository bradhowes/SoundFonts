// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <algorithm>
#include <array>

#include "Synthesizer.hpp"

namespace SF2 {

class Transform {
public:
    constexpr static int const MaxMIDIControllerValue = 127;

    enum struct Kind {
        linear,
        concave,
        convex,
        switched
    };

    enum struct Polarity {
        unipolar,
        bipolar
    };

    enum struct Direction {
        ascending,
        descending
    };

    Transform(Kind kind, Direction direction, Polarity polarity);

    double value(int controllerValue) const {
        controllerValue = ::std::max(::std::min(controllerValue, MaxMIDIControllerValue), 0);
        return (polarity_ == Polarity::unipolar) ? unipolarValue(controllerValue) : bipolarValue(controllerValue);
    }

private:
    using TransformArrayType = std::array<double, MaxMIDIControllerValue + 1>;

    double unipolarValue(int controllerValue) const { return active_[controllerValue]; }
    double bipolarValue(int controllerValue) const { return 2.0 * active_[controllerValue] - 1.0; }

    static TransformArrayType const& selectActive(Kind kind, Direction direction);

    static TransformArrayType const positiveLinear_;
    static TransformArrayType const negativeLinear_;
    static TransformArrayType const positiveConcave_;
    static TransformArrayType const negativeConcave_;
    static TransformArrayType const positiveConvex_;
    static TransformArrayType const negativeConvex_;
    static TransformArrayType const positiveSwitched_;
    static TransformArrayType const negativeSwitched_;

    TransformArrayType const& active_;
    Polarity polarity_;
};

}
