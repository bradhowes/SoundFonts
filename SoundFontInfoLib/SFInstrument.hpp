// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "BinaryStream.hpp"
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

    explicit SFInstrument(BinaryStream& is) {
        is.copyInto(this);
        trim_property(achInstName);
    }

    auto name() const -> auto{ return achInstName; }
    auto zoneIndex() const -> auto { return wInstBagNdx; }

    auto next() const -> auto { return *(this + 1); }
    auto zoneCount() const -> auto { return next().zoneIndex() - zoneIndex(); }

    void dump(std::string const& indent, int index) const
    {
        std::cout << indent << index << ": '" << name() << "' zoneIndex: " << zoneIndex() << " count: " << zoneCount()
        << std::endl;
    }

private:
    char achInstName[20];
    uint16_t wInstBagNdx;
};

}
