// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <algorithm>
#include <array>

namespace SF2 {
namespace Render {

class Transform {
public:
    constexpr static int const MaxMIDIControllerValue = 127;

    /**
     Kind specifies the curvature of the transformation function.
     - linear -- straight line from min to 1.0
     - concave -- curved line that slowly increases in value and then accelerates in change until reaching 1.
     - convex -- curved line that rapidly increases in value and then decelerates in change until reaching 1.
     - switched -- emits 0 for control values <= 64, and 1 for those > 64.
     */
    enum struct Kind {
        linear,
        concave,
        convex,
        switched
    };

    /// Polarity determins the lower bound: unipolar == 0, bipolar == -1.
    enum struct Polarity {
        unipolar,
        bipolar
    };

    /// Direction controls the ordering of the min/max values.
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

    static const TransformArrayType& selectActive(Kind kind, Direction direction);

    static TransformArrayType const positiveLinear_;
    static TransformArrayType const negativeLinear_;
    static TransformArrayType const positiveConcave_;
    static TransformArrayType const negativeConcave_;
    static TransformArrayType const positiveConvex_;
    static TransformArrayType const negativeConvex_;
    static TransformArrayType const positiveSwitched_;
    static TransformArrayType const negativeSwitched_;

    const TransformArrayType& active_;
    Polarity polarity_;
};

} // namespace Render
} // namespace SF2
