// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Amount.hpp"

namespace SF2 {
namespace Render {

class Range
{
public:
    Range(int low, int high) : low_{low}, high_{high} {}

    explicit Range(const Entity::Generator::Amount& range) : Range(range.low(), range.high()) {}

    bool contains(int value) const { return value >= low_ && value <= high_; }

    int low() const { return low_; }
    int high() const { return high_; }

private:
    int low_;
    int high_;
};


} // namespace Render
} // namespace SF2
