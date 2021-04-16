// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>

#include "Source.hpp"

using namespace SF2::Entity::Modulator;
namespace SF2 {
namespace Entity {
namespace Modulator {

std::ostream&
operator<<(std::ostream& os, const Source& mod)
{
    return os << "[type: " << mod.continuityTypeName()
    << " P: " << mod.polarity()
    << " D: " << mod.direction()
    << " CC: " << mod.isContinuousController()
    << " index: " << mod.rawIndex()
    << "]";
}

}
}
}
