// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>

#include "SFGeneratorAmount.hpp"
#include "SFGeneratorIndex.hpp"

namespace SF2 {

class Configuration
{
public:

    Configuration() : values_{} { setDefaults(); }

    const SFGeneratorAmount& operator[](SFGenIndex index) const { return values_[static_cast<size_t>(index)]; }

    SFGeneratorAmount& operator[](SFGenIndex index) { return values_[static_cast<size_t>(index)]; }

private:

    void setDefaults();

    void setAmount(SFGenIndex index, int16_t value) { (*this)[index].setAmount(value); }

    std::array<SFGeneratorAmount, static_cast<size_t>(SFGenIndex::numValues)> values_;
};

}
