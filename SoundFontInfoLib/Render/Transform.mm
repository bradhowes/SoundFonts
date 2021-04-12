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
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(index) / MaxMIDIControllerValue;
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeLinear_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(MaxMIDIControllerValue - index) / MaxMIDIControllerValue;
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveConcave_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = positiveConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeConcave_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = negativeConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - negativeConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - positiveConcaveCurve(index);
    }
    return init;
}();

Transform::TransformArrayType const Transform::positiveSwitched_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 0.0 : 1.0;
    }
    return init;
}();

Transform::TransformArrayType const Transform::negativeSwitched_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 1.0 : 0.0;
    }
    return init;
}();
