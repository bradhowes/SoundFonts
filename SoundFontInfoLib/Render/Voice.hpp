// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "Entity/Generator/Amount.hpp"
#include "Render/Zone.hpp"

namespace SF2 {
namespace Render {

class Voice
{
public:
    using Configuration = std::array<SFGeneratorAmount,static_cast<size_t>(SFGenIndex::numValues)>;

    Voice(const Zone& instrument, Zone const* globalInstrument, const Zone&) : configuration_{}
    {
        configuration_.fill(SFGeneratorAmount(0));
    }

private:
    SampleBuffer samples_;
};

}
}
