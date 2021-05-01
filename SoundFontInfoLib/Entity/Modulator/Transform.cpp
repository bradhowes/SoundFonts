// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "Entity/Modulator/Transform.hpp"

using namespace SF2::Entity::Modulator;
namespace SF2 {
namespace Entity {
namespace Modulator {

std::ostream&
operator<<(std::ostream& os, const Transform& value)
{
    return os << (value.kind() == Transform::Kind::linear ? "linear" : "absolute");
}

}
}
}
