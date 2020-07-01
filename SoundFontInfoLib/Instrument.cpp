// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"
#include "StringUtils.hpp"

using namespace SF2;

char const*
sfInst::load(char const* pos, size_t available)
{
    if (available < sizeof(*this)) throw FormatError;
    memcpy(this, pos, sizeof(*this));
    pos += sizeof(*this);
    return pos;
}

void
sfInst::dump(std::string const& indent, int index) const
{
    auto next = this + 1;
    std::string name(achInstName, 19);
    trim(name);
    std::cout << indent << index << ": '" << name
    << "' ibagIndex: " << wInstBagNdx << " count: " << (next->wInstBagNdx - wInstBagNdx) << std::endl;
}
