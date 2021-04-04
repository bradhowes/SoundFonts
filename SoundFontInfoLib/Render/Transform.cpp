// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "Transform.hpp"

using namespace SF2::Render;

int const Transform::MaxMIDIControllerValue;

const Transform::TransformArrayType& Transform::selectActive(Kind kind, Direction direction)
{
    switch (kind) {
        case Kind::linear: return direction == Direction::ascending ? positiveLinear_ : negativeLinear_; break;
        case Kind::concave: return direction == Direction::ascending ? positiveConcave_ : negativeConcave_; break;
        case Kind::convex: return direction == Direction::ascending ? positiveConvex_ : negativeConvex_; break;
        case Kind::switched: return direction == Direction::ascending ? positiveSwitched_ : negativeSwitched_; break;
    }
}

Transform::Transform(Kind kind, Direction direction, Polarity polarity)
: active_{selectActive(kind, direction)}, polarity_{polarity}
{}

static double positiveConcaveCurve(int index)
{
    return index == 127 ? 1.0 : -40.0 / 96.0 * log10(double(Transform::MaxMIDIControllerValue - index) /
                                                     Transform::MaxMIDIControllerValue);
}

static double negativeConcaveCurve(int index)
{
    // From SF2 spec - output = -20/96 * log((value^2)/(range^2)) == -40/96 * log(value / range)
    return index == 0 ? 1.0 : -40.0 / 96.0 * log10(double(index) / Transform::MaxMIDIControllerValue);
}

Transform::TransformArrayType const Transform::positiveLinear_ = [] {
    auto init = decltype(Transform::positiveLinear_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(index) / MaxMIDIControllerValue;
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeLinear_ = [] {
    auto init = decltype(Transform::negativeLinear_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(MaxMIDIControllerValue - index) / MaxMIDIControllerValue;
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveConcave_ = [] {
    auto init = decltype(Transform::positiveConcave_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = positiveConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeConcave_ = [] {
    auto init = decltype(Transform::negativeConcave_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = negativeConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveConvex_ = [] {
    auto init = decltype(Transform::positiveConvex_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - negativeConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeConvex_ = [] {
    auto init = decltype(Transform::negativeConvex_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - positiveConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveSwitched_ = [] {
    auto init = decltype(Transform::positiveSwitched_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 0.0 : 1.0;
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeSwitched_ = [] {
    auto init = decltype(Transform::negativeSwitched_){};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 1.0 : 0.0;
    }
    return init;
}();
