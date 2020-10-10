// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "Instrument.hpp"
#include "SFFile.hpp"

namespace SF2 {

class InstrumentCollection
{
public:
    InstrumentCollection(SFFile const& file);

    Instrument const& at(size_t index) const { return instruments_.at(index); }

private:
    std::vector<Instrument> instruments_;
};

}
