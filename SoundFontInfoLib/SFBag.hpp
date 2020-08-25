// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "BinaryStream.hpp"

namespace SF2 {

/**
 Memory layout of a 'ibag/pbag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4. The wGenNdx and wModNdx properties contain the first index
 of the generator/modulator that belongs to the instrument/preset zone. The number of generator or
 modulator settings is found by subtracting index value of this instance from the index value of the
 subsequent instance. This is guaranteed to be safe in a well-formed SF2 file, as all collections that
 operate in this way have a terminating instance whose index value is the total number of generators or
 modulators in the preset or instrument zones.
 */
struct SFBag {
    constexpr static size_t size = 4;

    SFBag(BinaryStream& is) { is.copyInto(this); }

    auto next() const -> SFBag const& { return *(this + 1); }

    auto generatorIndex() const -> auto { return wGenNdx; }
    auto generatorCount() const -> auto { return next().generatorIndex() - generatorIndex(); }

    auto modulatorIndex() const -> auto { return wModNdx; }
    auto modulatorCount() const -> auto { return next().modulatorIndex() - modulatorIndex(); }

    void dump(const std::string& indent, int index) const
    {
        std::cout << indent << index << ": genIndex: " << generatorIndex() << " count: " << generatorCount()
        << " modIndex: " << modulatorIndex() << " count: " << modulatorCount() << std::endl;
    }

private:
    uint16_t wGenNdx;
    uint16_t wModNdx;
};

}
