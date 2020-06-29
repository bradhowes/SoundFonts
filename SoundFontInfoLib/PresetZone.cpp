// Copyright © 2020 Brad Howes. All rights reserved.

#include "PresetZone.hpp"

using namespace SF2;

const char*
sfPresetBag::load(const char* pos, size_t available)
{
    if (available < 4) throw FormatError;
    memcpy(this, pos, 4);
    return pos + 4;
}

void
sfPresetBag::dump(const std::string& indent, int index) const
{
    auto next = this + 1;
    std::cout << indent << index
    << ": gen: " << wGenNdx
    << " count: " << (next->wGenNdx - wGenNdx)
    << " mod: " << wModNdx
    << " count: " << (next->wModNdx - wModNdx)
    << std::endl;
}
