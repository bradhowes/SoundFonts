// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>

#include "Entity/Modulator/Modulator.hpp"
#include "Render/Voice.hpp"

namespace SF2 {
namespace Render {

class Modulator {
public:

    Modulator(const Entity::Modulator::Modulator& mod, Voice& voice)
    : mod_{mod}, voice_{voice} {}

    double value() const { return 0.0; }

private:
    const Entity::Modulator::Modulator& mod_;
    Voice& voice_;
};

} // namespace Render
} // namespace SF2
