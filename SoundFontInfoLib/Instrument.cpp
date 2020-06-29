// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"
#include "StringUtils.hpp"

using namespace SF2;

const char*
sfInst::load(const char* pos, size_t available)
{
    if (available < sizeof(*this)) throw FormatError;
    memcpy(this, pos, sizeof(*this));
    pos += sizeof(*this);
    return pos;
}

void
sfInst::dump(const std::string& indent, int index) const
{
    std::string name(achInstName, 19);
    trim(name);
    std::cout << indent << index << ": '" << name
    << "' index: " << wInstBagNdx << std::endl;
}
