// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "IO/Pos.hpp"
#include "IO/StringUtils.hpp"
#include "Entity/SampleHeader.hpp"

namespace SF2 {
namespace Render {

class SampleOscillator {
public:
    SampleOscillator(double sampleRate, const Int* data, const Entity::SampleHeader& sampleHeader)
    : sampleRate_{sampleRate}, samples_{data}, header_{sampleHeader}
    {

    }

private:
    double sampleRate_;
    const Int* samples_;
    const Entity::SampleHeader& header_;
    
};

}
}
