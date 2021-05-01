// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Instrument.hpp"

using namespace SF2::Entity;

void
Instrument::dump(const std::string& indent, int index) const
{
    std::cout << indent << '[' << index << "] '" << name() << "' zoneIndex: " << firstZoneIndex()
    << " count: " << zoneCount() << std::endl;
}
