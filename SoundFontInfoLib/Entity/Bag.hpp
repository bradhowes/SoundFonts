// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdint>
#include <iostream>
#include <string>

#include "../IO/Pos.hpp"

namespace SF2 {
namespace Entity {

/**
 Memory layout of a 'ibag/pbag' entry in a sound font resource. Used to access packed values from a
 resource. The size of this must be 4. The wGenNdx and wModNdx properties contain the first index
 of the generator/modulator that belongs to the instrument/preset zone. The number of generator or
 modulator settings is found by subtracting index value of this instance from the index value of the
 subsequent instance. This is guaranteed to be safe in a well-formed SF2 file, as all collections that
 operate in this way have a terminating instance whose index value is the total number of generators or
 modulators in the preset or instrument zones.
 */
class Bag {
public:
    constexpr static size_t size = 4;

    explicit Bag(IO::Pos& pos) { pos = pos.readInto(*this); }

    uint16_t generatorIndex() const { return wGenNdx; }
    uint16_t generatorCount() const;

    uint16_t modulatorIndex() const { return wModNdx; }
    uint16_t modulatorCount() const;

    void dump(const std::string& indent, int index) const;

private:
    Bag const& next() const { return *(this + 1); }

    uint16_t wGenNdx;
    uint16_t wModNdx;
};

inline uint16_t Bag::generatorCount() const { return next().generatorIndex() - generatorIndex(); }
inline uint16_t Bag::modulatorCount() const { return next().modulatorIndex() - modulatorIndex(); }

inline void Bag::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": genIndex: " << generatorIndex() << " count: " << generatorCount()
    << " modIndex: " << modulatorIndex() << " count: " << modulatorCount() << std::endl;
}

}
}