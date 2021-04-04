// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "../IO/Pos.hpp"
#include "../IO/StringUtils.hpp"

namespace SF2 {
namespace Entity {

/**
 Memory layout of a 'inst' entry. The size of this is defined to be 22 bytes.

 An `instrument` is ultimately defined by its samples, but there can be multiple instruments defined that use the same
 sample source with different gen/mod settings (the sample source is indeed itself a generator setting).
 */
class Instrument {
public:
    constexpr static size_t size = 22;

    explicit Instrument(IO::Pos& pos) {
        assert(sizeof(*this) == size);
        pos = pos.readInto(*this);
        IO::trim_property(achInstName);
    }

    /// @returns the name of the instrument
    std::string name() const { return std::string(achInstName); }

    /// @returns the index of the first Zone of the instrument
    uint16_t firstZoneIndex() const { return wInstBagNdx; }

    /// @returns the number of instrument zones
    uint16_t zoneCount() const { return validateDiff((this + 1)->firstZoneIndex(), firstZoneIndex()); }

    void dump(const std::string& indent, int index) const;

private:

    // Verify that the next index is not less than the previous one.
    static uint16_t validateDiff(uint16_t next, uint16_t prev) {
        assert(next >= prev);
        return next - prev;
    }

    char achInstName[20];
    uint16_t wInstBagNdx;
};

inline void Instrument::dump(const std::string& indent, int index) const
{
    std::cout << indent << index << ": '" << name() << "' zoneIndex: " << firstZoneIndex() << " count: " << zoneCount()
    << std::endl;
}

}
}
