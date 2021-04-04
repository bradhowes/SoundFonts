// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>

#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Index.hpp"

namespace SF2 {
namespace Render {

class Configuration
{
public:

    Configuration() : values_{} { setDefaults(); }

    const Entity::Generator::Amount& operator[](Entity::Generator::Index index) const {
        return values_[static_cast<size_t>(index)];
    }

    Entity::Generator::Amount& operator[](Entity::Generator::Index index) {
        return values_[static_cast<size_t>(index)];
    }

private:

    void setDefaults();

    void setAmount(Entity::Generator::Index index, int16_t value) { (*this)[index].setAmount(value); }

    std::array<Entity::Generator::Amount, static_cast<size_t>(Entity::Generator::Index::numValues)> values_;
};

}
}
