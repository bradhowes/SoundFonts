// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "SFBag.hpp"
#include "SFFile.hpp"
#include "Zone.hpp"

namespace SF2 {

class Configuration;

class InstrumentZone : public Zone {
public:
    InstrumentZone(SFFile const& file, SFBag const& bag);

    void apply(Configuration& configuration) const { Zone::apply(configuration); }

private:
    SFSample const* sample_;
    uint8_t const* sampleData_;
};

}
