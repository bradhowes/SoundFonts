// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Pos.hpp"
#include "SFGeneratorDefinition.hpp"
#include "SFModulatorSource.hpp"
#include "SFTransform.hpp"

namespace SF2 {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 */
class SFModulator {
public:
    static constexpr size_t size = 10;

    explicit SFModulator(Pos& pos) { pos = pos.readInto(*this); }
    
    void dump(const std::string& indent, int index) const;

private:
    SFModulatorSource sfModSrcOper;
    SFGeneratorIndex sfModDestOper;
    int16_t modAmount;
    SFModulatorSource sfModAmtSrcOper;
    SFTransform sfModTransOper;
};

inline void SFModulator::dump(const std::string& indent, int index) const
{
    std::cout << indent << index
    << ": src: " << sfModSrcOper
    << " dest: " << SFGeneratorDefinition::definition(sfModDestOper).name()
    << " amount: " << modAmount
    << " op: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper
    << std::endl;
}

}
