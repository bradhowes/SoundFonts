// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Preset.hpp"

using namespace SF2::Entity;

void
Preset::dump(const std::string& indent, size_t index) const
{
  std::cout << indent << '[' << index << "] '" << name() << "' bank: " << bank() << " program: " << program()
  << " zoneIndex: " << firstZoneIndex() << " count: " << zoneCount() << std::endl;
}
