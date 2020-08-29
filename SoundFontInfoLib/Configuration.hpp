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
    Configuration() : values_{}
    {
        setDefaults();
    }

    SFGeneratorAmount& operator[](SFGenIndex index) { return values_[static_cast<size_t>(index)]; }

private:

    void setDefaults()
    {
        setAmount(SFGenIndex::initialFilterFc, 13500);
        setAmount(SFGenIndex::delayModLFO, -12000);
        setAmount(SFGenIndex::delayVibLFO, -12000);
        setAmount(SFGenIndex::delayModEnv, -12000);
        setAmount(SFGenIndex::attackModEnv, -12000);
        setAmount(SFGenIndex::holdModEnv, -12000);
        setAmount(SFGenIndex::decayModEnv, -12000);
        setAmount(SFGenIndex::releaseModEnv, -12000);
        setAmount(SFGenIndex::delayVolEnv, -12000);
        setAmount(SFGenIndex::attackVolEnv, -12000);
        setAmount(SFGenIndex::holdVolEnv, -12000);
        setAmount(SFGenIndex::decayVolEnv, -12000);
        setAmount(SFGenIndex::sustainVolEnv, -12000);
        setAmount(SFGenIndex::releaseVolEnv, -12000);
        setAmount(SFGenIndex::keynum, -1);
        setAmount(SFGenIndex::velocity, -1);
        setAmount(SFGenIndex::scaleTuning, 100);
        setAmount(SFGenIndex::overridingRootKey, -1);
    }

    void setAmount(SFGenIndex index, int16_t value) { (*this)[index].setAmount(value); }

    std::array<SFGeneratorAmount, static_cast<size_t>(SFGenIndex::numValues)> values_;
};

}
