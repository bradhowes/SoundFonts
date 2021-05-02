// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cassert>
#include <cmath>
#include <array>
#include <iosfwd>

#include "Entity/Modulator/Source.hpp"

namespace SF2 {
namespace DSP::Generators { void Generate(std::ostream&); }
namespace MIDI {

/**
 Transforms MIDI controller domain values (between 0 and 127) into various ranges. This currently only works with the
 `coarse` controller values.

 The conversion is done via a collection of lookup tables that map between [0, 127] and [0, 1] or [-1, 1]. Verified in
 Xcode 12.5 that the tables are built using precomputed values in a TEXT segment, and not via any initialization code.
 */
class ValueTransformer {
public:
    inline constexpr static short Min = 0;
    inline constexpr static short Max = 127;

    /// Since we have only 128 values to handle, use lookup tables for quick conversion
    inline constexpr static size_t TableSize = Max + 1;
    using TransformArrayType = std::array<double, TableSize>;

    /**
     Kind specifies the curvature of the MIDI value transformation function.
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
        unipolar = 0,
        bipolar = 1
    };

    /// Direction controls the ordering of the min/max values.
    enum struct Direction {
        ascending = 0,
        descending = 1
    };

    /// Domain controls how many values there are in the domain. Some domains start at 1 while others start at 0.
    enum struct Domain {
        zeroBased = 0,
        oneBased = 1
    };

    /**
     Create new value transformer from an SF2 modulator source definition

     @param source the source definition to use
     */
    explicit ValueTransformer(const Entity::Modulator::Source& source) :
    ValueTransformer(Kind(source.type()),
                     source.isMinToMax() ? Direction::ascending : Direction::descending,
                     source.isUnipolar() ? Polarity::unipolar : Polarity::bipolar)
    {}

    /**
     Convert a controller value.

     @param controllerValue value to convert between 0 and 127
     @returns transformed value
     */
    double value(short controllerValue) const { return active_[std::clamp<short>(controllerValue, 0, Max)]; }

private:

    /**
     Create new value transformer.

     @param kind mapping operation from controller domain to value range
     @param direction ordering from min to max
     @param polarity range lower and upper bounds
     */
    ValueTransformer(Kind kind, Direction direction, Polarity polarity);

    /**
     Locate the right table to use based on the transformation, direction, and polarity.

     @param kind the transformation function to apply
     @param direction the min/max ordering to use
     @param polarity the lower bound of the transformed result
     */
    static const TransformArrayType& selectActive(Kind kind, Direction direction, Polarity polarity);

    /**
     Generator function for the positive linear curve

     @param index the table index to generate the value for
     @returns transform value
     */
    static double positiveLinear(size_t index) { return double(index) / TableSize; }

    /**
     Generator function for the negative linear curve

     @param index the table index to generate the value for
     @returns transform value
     */
    static double negativeLinear(size_t index) { return 1.0 - positiveLinear(index); }

    static double positiveConcave(size_t index) {
        return index == (TableSize - 1) ? 1.0 : -40.0 / 96.0 * std::log10((127.0 - double(index)) / 127.0);
    }
    static double negativeConcave(size_t index) {
        return index == 0 ? 1.0 : -40.0 / 96.0 * std::log10(double(index) / 127.0);
    }

    static double positiveConvex(size_t index) {
        return index == 0 ? 0.0 : 1.0 - -40.0 / 96.0 * std::log10(double(index) / 127.0);
    }

    static double negativeConvex(size_t index) {
        return index == (TableSize - 1) ? 0.0 : 1.0 - -40.0 / 96.0 * std::log10(double(127.0 - index) / 127.0);
    }

    static double positiveSwitched(size_t index) { return index < TableSize / 2 ? 0.0 : 1.0; }

    static double negativeSwitched(size_t index) { return index < TableSize / 2 ? 1.0 : 0.0; }

    static TransformArrayType const positiveLinear_;
    static TransformArrayType const negativeLinear_;
    static TransformArrayType const positiveConcave_;
    static TransformArrayType const negativeConcave_;
    static TransformArrayType const positiveConvex_;
    static TransformArrayType const negativeConvex_;
    static TransformArrayType const positiveSwitched_;
    static TransformArrayType const negativeSwitched_;

    static TransformArrayType const positiveLinearBipolar_;
    static TransformArrayType const negativeLinearBipolar_;
    static TransformArrayType const positiveConcaveBipolar_;
    static TransformArrayType const negativeConcaveBipolar_;
    static TransformArrayType const positiveConvexBipolar_;
    static TransformArrayType const negativeConvexBipolar_;
    static TransformArrayType const positiveSwitchedBipolar_;
    static TransformArrayType const negativeSwitchedBipolar_;

    const TransformArrayType& active_;

    friend void DSP::Generators::Generate(std::ostream&);
};

} // namespace MIDI
} // namespace SF2
