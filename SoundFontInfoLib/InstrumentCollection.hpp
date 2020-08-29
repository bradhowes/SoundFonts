// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "Instrument.hpp"
#include "SFFile.hpp"

namespace SF2 {

class InstrumentCollection
{
public:
    InstrumentCollection(SFFile const& file) :
    instruments_{}
    {
        // Do *not* process the last record. It is a sentinal used only for bag calculations.
        auto count = file.instruments.size() - 1;
        instruments_.reserve(count);
        for (SFInstrument const& configuration : file.instruments.slice(0, count)) {
            instruments_.emplace_back(file, configuration);
        }
    }

    Instrument const& at(size_t index) const { return instruments_.at(index); }

private:
    std::vector<Instrument> instruments_;
};

}
