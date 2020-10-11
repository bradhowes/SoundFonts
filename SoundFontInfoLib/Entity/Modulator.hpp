// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "../IO/Pos.hpp"

#include "GeneratorDefinition.hpp"
#include "ModulatorSource.hpp"
#include "Transform.hpp"

namespace SF2 {
namespace Entity {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 */
class Modulator {
public:
    static constexpr size_t size = 10;

    explicit Modulator(IO::Pos& pos) { pos = pos.readInto(*this); }
    
    void dump(const std::string& indent, int index) const;

private:
    ModulatorSource sfModSrcOper;
    GeneratorIndex sfModDestOper;
    int16_t modAmount;
    ModulatorSource sfModAmtSrcOper;
    Transform sfModTransOper;
};

inline void Modulator::dump(const std::string& indent, int index) const
{
    std::cout << indent << index
    << ": src: " << sfModSrcOper
    << " dest: " << GeneratorDefinition::definition(sfModDestOper).name()
    << " amount: " << modAmount
    << " op: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper
    << std::endl;
}

}
}
