// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "Instrument.hpp"

namespace SF2 {
namespace IO { class File; }
namespace Render {

class InstrumentCollection
{
public:
    InstrumentCollection(const IO::File& file);

    const Instrument& at(size_t index) const { return instruments_.at(index); }

private:
    std::vector<Instrument> instruments_;
};

}
}
