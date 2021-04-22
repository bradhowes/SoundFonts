// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <algorithm>
#include <array>

#include "Entity/Modulator/Source.hpp"

namespace SF2 {
namespace Render {

/**
 Transforms MIDI controller domain values (between 0 and 127) into various ranges. This currently only works with the
 `coarse` controller values. 
 */
class Transform {
public:
    constexpr static int const MaxMIDIControllerValue = 127;

    /**
     Kind specifies the curvature of the transformation function.
     - linear -- straight line from min to 1.0
     - concave -- curved line that slowly increases in value and then accelerates in change until reaching 1.
     - convex -- curved line that rapidly increases in value and then decelerates in change until reaching 1.
     - switched -- emits 0 for control values <= 64, and 1 for those > 64.

     NOTE: keep raw values aligned with Entity::Modulator::Source::ContinuityType.
     */
    enum struct Kind {
        linear = 0,
        concave,
        convex,
        switched
    };

    /// Polarity determines the lower bound: unipolar = 0, bipolar = -1.
    enum struct Polarity {
        unipolar,
        bipolar
    };

    /// Direction controls the ordering of the min/max values.
    enum struct Direction {
        ascending,
        descending
    };

    /**
     Create new transform

     @param kind mapping operation from controller domain to value range
     @param direction ordering from min to max
     @param polarity lower bound of range
     */
    Transform(Kind kind, Direction direction, Polarity polarity);

    Transform(const Entity::Modulator::Source& source) :
    Transform(Kind(source.type()),
              source.isMinToMax() ? Direction::ascending : Direction::descending,
              source.isUnipolar() ? Polarity::unipolar : Polarity::bipolar)
    {
        ;
    }

    /**
     Convert a controller value.

     @param controllerValue value to convert between 0 and 127
     @returns transformed value
     */
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
