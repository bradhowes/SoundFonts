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
 
 Defines a mapping of a modulator to a generator so that a modulator can affect the value given by a generator. Per the
 spec a modulator can have two sources. If the first one is not set, then the modulator will always return 0.0. The
 second one is optional -- if it exists then it will scale the result of the previous source value. Otherwise, it just
 acts as if the source returned 1.0.
 */
class Modulator {
public:
    static constexpr size_t size = 10;

    static std::array<Modulator, 10> const defaults;

    /**
     Construct instance from contents of SF2 file.

     @param pos location to read from
     */
    explicit Modulator(IO::Pos& pos) { assert(sizeof(*this) == size);
        pos = pos.readInto(*this);
    }

    /**
     Construct instance from values. Used to define default mods.
     */
    Modulator(Source modSrcOper, Generator::Index dest, int16_t amount, Source modAmtSrcOper, Transform xform) :
    sfModSrcOper{modSrcOper}, sfModDestOper{dest}, modAmount{amount}, sfModAmtSrcOper{modAmtSrcOper},
    sfModTransOper{xform} {}

    void dump(const std::string& indent, int index) const;

    /// @returns the source of data for the modulator
    Source modulatorSource() const { return sfModSrcOper; }

    /// @returns the destination (generator) for the modulator
    Generator::Index destination() const { return sfModDestOper; }

    /// @returns the maximum deviation that a modulator can apply to a generator
    Int amount() const { return modAmount; }

    /// @returns the second source of data for the modulator
    Source modulationAmountSource() const { return sfModAmtSrcOper; }

    /// @returns the transform to apply to values created by the modulator
    Transform transform() const { return sfModTransOper; }

private:
    Source sfModSrcOper;
    Generator::Index sfModDestOper;
    Int modAmount;
    Source sfModAmtSrcOper;
    Transform sfModTransOper;
};

} // end namespace Modulator
} // end namespace Entity
} // end namespace SF2
