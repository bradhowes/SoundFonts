// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Pos.hpp"
#include "StringUtils.hpp"

namespace SF2 {

/**
 Memory layout of a 'inst' entry. The size of this is defined to be 22 bytes.

 An `instrument` is ultimately defined by its samples, but there can be multiple instruments defined that use the same sample source with different gen/mod settings
 (the sample source is indeed a gen setting).
 */
class SFInstrument {
public:
    constexpr static size_t size = 22;

    explicit SFInstrument(Pos& pos) {
        pos = pos.readInto(*this);
        trim_property(achInstName);
    }

    std::string name() const { return std::string(achInstName); }
    uint16_t zoneIndex() const { return wInstBagNdx; }
    uint16_t zoneCount() const { return (this + 1)->zoneIndex() - zoneIndex(); }

    void dump(std::string const& indent, int index) const;

private:
    char achInstName[20];
    uint16_t wInstBagNdx;
};

inline void SFInstrument::dump(std::string const& indent, int index) const
{
    std::cout << indent << index << ": '" << name() << "' zoneIndex: " << zoneIndex() << " count: " << zoneCount()
    << std::endl;
}

}
