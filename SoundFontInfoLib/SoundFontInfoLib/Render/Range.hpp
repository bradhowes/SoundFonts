// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Amount.hpp"

namespace SF2::Render {

/**
 Representation of a range of values between low and high values inclusive. It can answer if a given value is within
 the range.
 */
template <typename T>
class Range
{
public:
    using ValueType = T;

    /**
     Construct new range between two values.

     @param low the first value in the range
     @param high the last value in the range
     */
    Range(ValueType low, ValueType high) : low_{low}, high_{high} {}

    /**
     Conversion constructor from Entity::Generator::Amount

     @param range the union value to use for range bounds
     */
    explicit Range(const Entity::Generator::Amount& range) : Range(range.low(), range.high()) {}

    /**
     Determine if a given value is within the defined range.

     @param value the value to test
     @returns true if so
     */
    bool contains(ValueType value) const { return value >= low_ && value <= high_; }

    /// @returns lowest value in range
    ValueType low() const { return low_; }

    /// @returns highest value in range
    ValueType high() const { return high_; }

private:
    ValueType low_;
    ValueType high_;
};

} // namespace SF2::Render
