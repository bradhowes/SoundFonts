// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/DSP.hpp"
#include "ValueTransformer.hpp"

using namespace SF2::MIDI;

ValueTransformer::ValueTransformer(Kind kind, Direction direction, Polarity polarity)
: active_{selectActive(kind, direction, polarity)}
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

ValueTransformer::TransformArrayType const ValueTransformer::positiveLinearBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(double(index) / init.size());
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeLinearBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(1.0 - double(index) / init.size());
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConcaveBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(positiveConcaveCurveGenerator(index));
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConcaveBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(negativeConcaveCurveGenerator(index));
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveConvexBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(1.0 - negativeConcaveCurveGenerator(index));
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeConvexBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = DSP::unipolarToBipolar(1.0 - positiveConcaveCurveGenerator(index));
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::positiveSwitchedBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? -1.0 : 1.0;
    }
    return init;
}();

ValueTransformer::TransformArrayType const ValueTransformer::negativeSwitchedBipolar_ = [] {
    TransformArrayType init{};
    for (auto index = 0; index < init.size(); ++index) {
        init[index] = index < init.size() / 2.0 ? 1.0 : -1.0;
    }
    return init;
}();

const ValueTransformer::TransformArrayType& ValueTransformer::selectActive(Kind kind, Direction direction,
                                                                           Polarity polarity) {
    if (polarity == Polarity::unipolar) {
        switch (kind) {
            case Kind::linear:
                return direction == Direction::ascending ? positiveLinear_ : negativeLinear_;
                break;
            case Kind::concave:
                return direction == Direction::ascending ? positiveConcave_ : negativeConcave_;
                break;
            case Kind::convex:
                return direction == Direction::ascending ? positiveConvex_ : negativeConvex_;
                break;
            case Kind::switched:
                return direction == Direction::ascending ? positiveSwitched_ : negativeSwitched_;
                break;
        }
    }
    else {
        switch (kind) {
            case Kind::linear:
                return direction == Direction::ascending ? positiveLinearBipolar_ : negativeLinearBipolar_;
                break;
            case Kind::concave:
                return direction == Direction::ascending ? positiveConcaveBipolar_ : negativeConcaveBipolar_;
                break;
            case Kind::convex:
                return direction == Direction::ascending ? positiveConvexBipolar_ : negativeConvexBipolar_;
                break;
            case Kind::switched:
                return direction == Direction::ascending ? positiveSwitchedBipolar_ : negativeSwitchedBipolar_;
                break;
        }
    }
}
