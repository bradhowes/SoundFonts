// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Bag.hpp"

using namespace SF2::Entity;

void
Bag::dump(const std::string& indent, size_t index) const
{
  std::cout << indent << '[' << index << "] genIndex: " << firstGeneratorIndex() << " count: " << generatorCount()
  << " modIndex: " << firstModulatorIndex() << " count: " << modulatorCount() << std::endl;
}
