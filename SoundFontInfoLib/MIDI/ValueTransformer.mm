// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "ValueTransformer.hpp"

using namespace SF2::MIDI;

ValueTransformer::ValueTransformer(Kind kind, Direction direction, Polarity polarity)
: active_{selectActive(kind, direction)}, polarity_{polarity}
{}

ValueTransformer::TransformArrayType const ValueTransformer::positiveLinear_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = double(index) / init.size();
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeLinear_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - double(index) / init.size();
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConcave_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = positiveConcaveCurveGenerator(index);
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConcave_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = negativeConcaveCurveGenerator(index);
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - negativeConcaveCurveGenerator(index);
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConvex_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = 1.0 - positiveConcaveCurveGenerator(index);
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveSwitched_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 0.0 : 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeSwitched_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 1.0 : 0.0;
    }
    return init;
}();

const ValueTransformer::TransformArrayType& ValueTransformer::selectActive(Kind kind, Direction direction)
{
    switch (kind) {
        case Kind::linear: return direction == Direction::ascending ? positiveLinear_ : negativeLinear_; break;
        case Kind::concave: return direction == Direction::ascending ? positiveConcave_ : negativeConcave_; break;
        case Kind::convex: return direction == Direction::ascending ? positiveConvex_ : negativeConvex_; break;
        case Kind::switched: return direction == Direction::ascending ? positiveSwitched_ : negativeSwitched_; break;
    }
}
