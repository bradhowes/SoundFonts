// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>

#include "../Entity/GeneratorAmount.hpp"
#include "../Entity/GeneratorIndex.hpp"

namespace SF2 {
namespace Render {

class Configuration
{
public:

    Configuration() : values_{} { setDefaults(); }

    const Entity::GeneratorAmount& operator[](Entity::GenIndex index) const { return values_[static_cast<size_t>(index)]; }

    Entity::GeneratorAmount& operator[](Entity::GenIndex index) { return values_[static_cast<size_t>(index)]; }

private:

    void setDefaults();

    void setAmount(Entity::GenIndex index, int16_t value) { (*this)[index].setAmount(value); }

    std::array<Entity::GeneratorAmount, static_cast<size_t>(Entity::GenIndex::numValues)> values_;
};

}
}
