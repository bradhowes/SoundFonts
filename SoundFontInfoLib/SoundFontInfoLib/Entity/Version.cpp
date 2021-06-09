// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Version.hpp"

using namespace SF2::Entity;

void
Version::dump(const std::string& indent) const
{
  std::cout << indent << "major: " << wMajor << " minor: " << wMinor << std::endl;
}
