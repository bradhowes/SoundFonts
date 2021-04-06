// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "Types.hpp"
#include "IO/Pos.hpp"
#include "Entity/Generator/Definition.hpp"
#include "Entity/Generator/Index.hpp"
#include "Entity/Modulator/Source.hpp"
#include "Entity/Modulator/Transform.hpp"

namespace SF2 {
namespace Entity {
namespace Modulator {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 Defines a mapping of a modulator.

 Per the 2.06 pec, there are no 'pmod' modulators. There are 10 default ones that are present at the instrument level.
 */
class Modulator {
public:
    static constexpr size_t size = 10;

    static std::array<Modulator, 10> const defaults_;

    explicit Modulator(IO::Pos& pos) { assert(sizeof(*this) == size); pos = pos.readInto(*this); }

    Modulator(Source modSrcOper, Generator::Index dest, int16_t amount, Source modAmtSrcOper, Transform xform) :
    sfModSrcOper{modSrcOper}, sfModDestOper{dest}, modAmount{amount}, sfModAmtSrcOper{modAmtSrcOper},
    sfModTransOper{xform} {}

    void dump(const std::string& indent, int index) const;

private:
    Source sfModSrcOper;
    Generator::Index sfModDestOper;
    Int modAmount;
    Source sfModAmtSrcOper;
    Transform sfModTransOper;
};

inline void Modulator::dump(const std::string& indent, int index) const
{
    std::cout << indent << index
    << ": src: " << sfModSrcOper
    << " dest: " << Generator::Definition::definition(sfModDestOper).name()
    << " amount: " << modAmount
    << " op: " << sfModAmtSrcOper
    << " xform: " << sfModTransOper
    << std::endl;
}

}
}
}
