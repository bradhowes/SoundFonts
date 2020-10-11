// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "SFGenerator.hpp"
#include "Zone.hpp"

namespace SF2 {
namespace Render {

class Voice
{
public:
    using Configuration = std::array<SFGeneratorAmount,static_cast<size_t>(SFGenIndex::numValues)>;

    Voice(Zone const& instrument, Zone const* globalInstrument, Zone const&) : configuration_{}
    {
        configuration_.fill(SFGeneratorAmount(0));

    }

private:
    Configuration configuration_;
};

}
}
