// Copyright © 2020 Brad Howes. All rights reserved.

#include "InstrumentZone.hpp"

using namespace SF2;

const char*
sfInstBag::load(const char* pos, size_t available)
{
    if (available < sizeof(*this)) throw FormatError;
    memcpy(this, pos, sizeof(*this));
    return pos += sizeof(*this);
}

void
sfInstBag::dump(const std::string &indent, int index) const
{
    auto next = this + 1;
    std::cout << indent << index
    << ": gen: " << wInstGenNdx
    << " count: " << (next->wInstGenNdx - wInstGenNdx)
    << " mod: " << wInstModNdx << " count: " << (next->wInstModNdx - wInstModNdx)
    << std::endl;
}
