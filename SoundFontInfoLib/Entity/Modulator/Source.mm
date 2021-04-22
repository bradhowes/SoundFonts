// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>
#include <sstream>

#include "Source.hpp"

using namespace SF2::Entity::Modulator;

std::string
Source::description() const {
    std::ostringstream os;
    os << "[type: " << continuityTypeName()
    << " P: " << polarity()
    << " D: " << direction()
    << " CC: " << isContinuousController()
    << " index: " << rawIndex()
    << "]";
    return os.str();
}

namespace SF2 {
namespace Entity {
namespace Modulator {

std::ostream&
operator<<(std::ostream& os, const Source& mod)
{
    return os << mod.description();
}

}
}
}
