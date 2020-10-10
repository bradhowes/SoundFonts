// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "SFBag.hpp"

using namespace SF2;

void
SFBag::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": genIndex: " << generatorIndex() << " count: " << generatorCount()
    << " modIndex: " << modulatorIndex() << " count: " << modulatorCount() << std::endl;
}
